#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["boto3", "rich", "tzdata"]
# ///

"""
wasabi_traffic - daily egress and ingress per bucket, from Wasabi access logs.

Egress  = BytesSent on successful GET and LIST requests.
Ingress = ObjectSize on successful PUT/POST/MULTIPART requests.

Needs bucket logging enabled on each source bucket, all pointing at one logging
bucket. Logs only cover the period since you turned logging on. Read-only.

Usage:
  wasabi_traffic.py                       # every bucket that has logging enabled
  wasabi_traffic.py -b my-logs
  wasabi_traffic.py -b my-logs --days 30
  wasabi_traffic.py --profile wasabi -b XXBUCKET --prefix YYPREFIX/ --days 30

Env: WASABI_LOG_BUCKET, WASABI_REGION, AWS_PROFILE
"""

import argparse
import os
import re
import sys
from collections import Counter
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, time, timedelta, timezone
from zoneinfo import ZoneInfo

import boto3
from botocore.config import Config
from botocore.exceptions import BotoCoreError, ClientError, NoCredentialsError
from rich import box
from rich.console import Console
from rich.table import Table

# Wasabi access log fields, in order, per the header line of every log object.
# Wasabi appends new fields over time (TLS-Version arrived after their docs were
# published), so this list can run short of what a real record carries.
FIELDS = [
    "bucket_owner", "bucket", "time", "remote_ip", "requester", "request_id",
    "operation", "key", "request_uri", "http_status", "error_code",
    "bytes_sent", "object_size", "total_time", "turn_around_time",
    "referrer", "user_agent", "tls_version", "version_id",
]
IDX = {name: i for i, name in enumerate(FIELDS)}
# Everything we read lives at or before object_size, so a record only has to be
# long enough for that. Trailing fields we do not use may come and go.
MIN_FIELDS = IDX["object_size"] + 1

# One token is a [bracketed] group, a "quoted" string, or a run of non-space.
TOKEN_RE = re.compile(r'\[[^\]]*\]|"(?:[^"\\]|\\.)*"|\S+')
# Every log object opens with a "Record format: [...]" line and a ==== rule.
HEADER_RE = re.compile(r"^(Record format:|\s*=+\s*$)")
GET_RE = re.compile(r"(?:^|\.)(?:REST\.)?GET\.OBJECT\b", re.IGNORECASE)
LIST_RE = re.compile(r"\bLIST\b|REST\.GET\.BUCKET\b|S3\.ListBucket\b", re.IGNORECASE)
PUT_RE = re.compile(r"(?:REST\.)?(?:PUT|POST|MULTIPART)", re.IGNORECASE)

# Logs land well after the requests they describe, so scan past the window and
# filter on each record's own timestamp.
DELIVERY_LAG = timedelta(days=2)
# Access logs are small. Anything huge is not a log, so don't download it: that
# guards against pointing --logging-bucket at a data bucket by mistake.
MAX_OBJECT_BYTES = 64_000_000

console = Console()


class Tally:
    """Byte and call counts, each keyed by (day, bucket)."""

    def __init__(self):
        self.egress = Counter()
        self.ingress = Counter()
        self.gets = Counter()
        self.lists = Counter()
        self.records = 0

    def merge(self, other):
        self.egress.update(other.egress)
        self.ingress.update(other.ingress)
        self.gets.update(other.gets)
        self.lists.update(other.lists)
        self.records += other.records


def human_bytes(n):
    """Decimal units, because that is how Wasabi bills."""
    for unit in ("B", "KB", "MB", "GB", "TB", "PB"):
        if abs(n) < 1000 or unit == "PB":
            return f"{n:,.0f} {unit}" if unit == "B" else f"{n:,.2f} {unit}"
        n /= 1000


def safe_int(value):
    try:
        return int(value)
    except ValueError:
        return 0  # Unset fields are logged as "-".


def unwrap(token):
    """Drop the [] or "" that the log format puts around some fields."""
    if token.startswith("[") and token.endswith("]"):
        return token[1:-1]
    if token.startswith('"') and token.endswith('"'):
        return token[1:-1]
    return token


def parse_line(line):
    """Split one access log record into its fields, or None if malformed."""
    tokens = TOKEN_RE.findall(line)
    if len(tokens) < MIN_FIELDS:
        return None
    parts = [unwrap(token) for token in tokens[:len(FIELDS)]]
    return parts + ["-"] * (len(FIELDS) - len(parts))


def scan(s3, bucket, key, start, end, tz):
    """Read one log object and tally the records that fall inside the window."""
    tally = Tally()
    for raw in s3.get_object(Bucket=bucket, Key=key)["Body"].read().splitlines():
        line = raw.decode("utf-8", errors="replace").strip()
        parts = None if not line or HEADER_RE.match(line) else parse_line(line)
        if parts is None:
            continue
        tally.records += 1

        try:
            stamp = datetime.strptime(parts[IDX["time"]], "%d/%b/%Y:%H:%M:%S %z")
        except ValueError:
            continue
        if not (start <= stamp < end) or not parts[IDX["http_status"]].startswith("2"):
            continue

        op = parts[IDX["operation"]]
        slot = (stamp.astimezone(tz).date(), parts[IDX["bucket"]])
        if GET_RE.search(op):
            tally.egress[slot] += safe_int(parts[IDX["bytes_sent"]])
            tally.gets[slot] += 1
        elif LIST_RE.search(op):
            tally.egress[slot] += safe_int(parts[IDX["bytes_sent"]])
            tally.lists[slot] += 1
        elif PUT_RE.search(op):
            tally.ingress[slot] += safe_int(parts[IDX["object_size"]])
    return tally


def log_targets(s3):
    """Distinct buckets that other buckets deliver their access logs to.

    Buckets in another region answer with an error rather than a config, so they
    are skipped: pass --region to include them.
    """
    targets = set()
    for bucket in s3.list_buckets().get("Buckets", []):
        try:
            config = s3.get_bucket_logging(Bucket=bucket["Name"]).get("LoggingEnabled")
        except (ClientError, BotoCoreError):
            continue
        if config:
            targets.add(config["TargetBucket"])
    return sorted(targets)


def log_keys(s3, bucket, prefix, start, end):
    """Log objects that could hold records for the window."""
    kwargs = {"Bucket": bucket, "Prefix": prefix} if prefix else {"Bucket": bucket}
    keys = []
    for page in s3.get_paginator("list_objects_v2").paginate(**kwargs):
        for obj in page.get("Contents", []):
            if (obj["Size"] and obj["Size"] <= MAX_OBJECT_BYTES
                    and start - timedelta(hours=1) <= obj["LastModified"] < end + DELIVERY_LAG):
                keys.append(obj["Key"])
    return keys


def slots(tally):
    """Every (day, bucket) pair that saw any activity."""
    return set(tally.egress) | set(tally.ingress) | set(tally.gets) | set(tally.lists)


def sums(tally, keys):
    """Totals over the given (day, bucket) keys, as display strings."""
    egress = sum(tally.egress[k] for k in keys)
    return [
        f"{sum(tally.gets[k] for k in keys):,}",
        f"{sum(tally.lists[k] for k in keys):,}",
        human_bytes(egress),
        human_bytes(sum(tally.ingress[k] for k in keys)),
    ]


def usage_table(tally):
    """A day-total row per day, its buckets underneath, and a grand total."""
    table = Table(box=box.SQUARE, header_style="bold", pad_edge=False)
    table.add_column("Date", no_wrap=True)
    table.add_column("Bucket", overflow="ellipsis")
    table.add_column("GETs", justify="right", no_wrap=True)
    table.add_column("LISTs", justify="right", no_wrap=True)
    table.add_column("Egress", justify="right", no_wrap=True, style="bright_green")
    table.add_column("Ingress", justify="right", no_wrap=True, style="bright_cyan")

    pairs = slots(tally)
    for day in sorted({day for day, _ in pairs}):
        buckets = sorted((b for d, b in pairs if d == day),
                         key=lambda b: -tally.egress[(day, b)])
        table.add_section()
        table.add_row(f"{day:%Y-%m-%d}", "All",
                      *sums(tally, [(day, b) for b in buckets]), style="bold")
        for bucket in buckets:
            table.add_row("", f" - {bucket}", *sums(tally, [(day, bucket)]))

    table.add_section()
    table.add_row("Total", "", *sums(tally, pairs), style="bold")
    return table


def main():
    parser = argparse.ArgumentParser(description=(__doc__ or "").split("\n")[1])
    parser.add_argument("-b", "--logging-bucket", default=os.environ.get("WASABI_LOG_BUCKET"),
                        help="bucket the access logs are delivered to; default is every "
                             "bucket that has logging enabled [env: WASABI_LOG_BUCKET]")
    parser.add_argument("--region", default=os.environ.get("WASABI_REGION", "ap-southeast-2"),
                        help="Wasabi region (default: ap-southeast-2) [env: WASABI_REGION]")
    parser.add_argument("--profile", default=os.environ.get("AWS_PROFILE"))
    parser.add_argument("--prefix", default="", help="only scan log keys under this prefix")
    parser.add_argument("--days", type=int, default=7, help="days back to report (default: 7)")
    parser.add_argument("--tz", help="timezone for day boundaries (default: system local)")
    parser.add_argument("--jobs", type=int, default=16, help="parallel downloads (default: 16)")
    args = parser.parse_args()

    tz = ZoneInfo(args.tz) if args.tz else datetime.now().astimezone().tzinfo
    until = datetime.now(tz).date()
    since = until - timedelta(days=max(args.days, 1) - 1)
    start = datetime.combine(since, time.min, tzinfo=tz).astimezone(timezone.utc)
    end = datetime.combine(until + timedelta(days=1), time.min, tzinfo=tz).astimezone(timezone.utc)

    try:
        session = boto3.Session(profile_name=args.profile, region_name=args.region)
        s3 = session.client("s3", endpoint_url=f"https://s3.{args.region}.wasabisys.com",
                            config=Config(s3={"addressing_style": "virtual"}))
        with console.status("[dim]Finding logs...[/]"):
            targets = ([args.logging_bucket] if args.logging_bucket else log_targets(s3))
            keys = [(target, key) for target in targets
                    for key in log_keys(s3, target, args.prefix, start, end)]
    except NoCredentialsError:
        sys.exit("No credentials. Use --profile or set AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY.")
    except ClientError as exc:
        sys.exit(f"Could not read logs: {exc}")
    except BotoCoreError as exc:
        sys.exit(f"Could not get credentials for profile '{args.profile}': {exc}")

    if not targets:
        sys.exit(f"No bucket in {args.region} has logging enabled, so there is nothing "
                 "to read. Turn on Bucket Logging, or pass -b if the logs live elsewhere.")
    if not keys:
        sys.exit(f"No logs in {', '.join(targets)} for {since} to {until}. "
                 "Bucket logging only records from when you enabled it.")

    tally, failed = Tally(), 0
    with console.status(f"[dim]Reading {len(keys):,} log objects...[/]"):
        with ThreadPoolExecutor(max_workers=args.jobs) as pool:
            futures = [pool.submit(scan, s3, target, key, start, end, tz)
                       for target, key in keys]
            for future in as_completed(futures):
                try:
                    tally.merge(future.result())
                except Exception:
                    failed += 1

    console.print()
    if slots(tally):
        console.print(usage_table(tally))
    else:
        console.print(f"[yellow]No requests logged between {since} and {until}.[/]")
    console.print(f"\n[dim]{since} to {until} · logs from {', '.join(targets)} · "
                  f"{len(keys):,} objects · "
                  f"{tally.records:,} records[/]")
    if failed:
        console.print(f"[yellow]{failed} log object(s) could not be read.[/]")


if __name__ == "__main__":
    main()
