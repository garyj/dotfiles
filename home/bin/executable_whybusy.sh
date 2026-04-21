#!/usr/bin/env bash
# whybusy: one-shot Linux performance snapshot, optionally analysed by Claude.
#
# Usage: whybusy.sh [--raw] [--deep] [--model MODEL]
#   --raw, -r         Print collected data only; skip the LLM call.
#   --deep, -d        Include extra/privileged collections; privileged bits
#                     only run if already root (e.g. sudo whybusy.sh --deep).
#   --model MODEL     Claude model override (passed through to claude CLI).
#   -h, --help        Show this help.

set -uo pipefail

RAW=0
DEEP=0
MODEL=""

while (($#)); do
  case "$1" in
    --raw | -r) RAW=1 ;;
    --deep | -d) DEEP=1 ;;
    --model)
      MODEL="${2:-}"
      shift
      ;;
    -h | --help)
      sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "unknown arg: $1" >&2
      exit 2
      ;;
  esac
  shift
done

TMP="$(mktemp -t whybusy.XXXXXX)"
trap 'rm -f "$TMP"' EXIT

have() { command -v "$1" >/dev/null 2>&1; }
section() { printf '\n## %s\n' "$1" >>"$TMP"; }
run() {
  local label="$1"
  shift
  section "$label"
  "$@" >>"$TMP" 2>&1 || echo "(command failed or unavailable)" >>"$TMP"
}

{
  echo "# whybusy snapshot"
  echo "host=$(uname -n) kernel=$(uname -r) date=$(date -Is) euid=$EUID"
} >"$TMP"

run "loadavg+cpus" bash -c 'echo "loadavg: $(cat /proc/loadavg)"; echo "nproc: $(nproc)"; echo "uptime: $(uptime -p)"'
run "top"          bash -c 'top -bn1 | head -25'
run "vmstat"       vmstat 1 5
have iostat  && run "iostat"     iostat -xz 1 3
have pidstat && run "pidstat-io" pidstat -d 1 3
run "pressure/cpu"    cat /proc/pressure/cpu
run "pressure/io"     cat /proc/pressure/io
run "pressure/memory" cat /proc/pressure/memory

section "d-state (8 samples, 0.5s apart)"
for _ in $(seq 1 8); do
  ps -eo state,pid,user,comm | awk '$1 ~ /D/' >>"$TMP" 2>/dev/null || true
  echo "---" >>"$TMP"
  sleep 0.5
done

run "memory"  free -h
run "swapon"  swapon --show
run "top-rss" bash -c 'ps axo pid,user,pcpu,pmem,rss,comm --sort=-rss | head -15'
run "top-cpu" bash -c 'ps axo pid,user,pcpu,pmem,rss,comm --sort=-pcpu | head -15'
run "lsblk"   lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,ROTA,MODEL
run "df"      df -hT -x tmpfs -x devtmpfs -x squashfs -x overlay
have ss          && run "sockets" bash -c 'ss -s; echo; ss -tunaHp 2>/dev/null | head -20'
have sensors     && run "thermal" sensors -A
have nvidia-smi  && run "gpu-nvidia" nvidia-smi --query-gpu=name,driver_version,pstate,power.draw,utilization.gpu,memory.used,memory.total,temperature.gpu --format=csv
run "dmesg-tail"   bash -c 'dmesg 2>/dev/null | tail -40'
run "journal-warn" bash -c 'journalctl --since "15 min ago" -p warning --no-pager 2>/dev/null | tail -40'

if ((DEEP)); then
  if ((EUID == 0)); then
    have iotop && run "iotop (deep)" iotop -boP -n 2 -d 1
    section "pm-kworkers (deep)"
    for pid in $(ps -eo pid,comm | awk '/kworker.*\+pm/ {print $1}'); do
      {
        echo "== pid $pid =="
        ps -o pid,etime,time,pcpu,comm -p "$pid" 2>/dev/null
        cat /proc/"$pid"/stack 2>/dev/null | head -10
        echo
      } >>"$TMP"
    done
  else
    section "deep skipped"
    echo "deep collections require root: re-run with 'sudo $0 --deep'" >>"$TMP"
  fi
fi

if ((RAW)); then
  cat "$TMP"
  exit 0
fi

if ! have claude; then
  echo "claude CLI not found; printing raw snapshot" >&2
  cat "$TMP"
  exit 0
fi

SYSTEM_PROMPT='You are a senior Linux performance analyst. The input is a single read-only snapshot from a Linux workstation. Diagnose real or apparent bottlenecks.

Hard rules — apply before drawing conclusions:
- `%wa`/iowait is idle-CPU accounting. Cross-check against `iostat %util`, r_await/w_await. High %wa with low %util (<5%) usually means a TASK_UNINTERRUPTIBLE kernel thread (e.g. `kworker/*+pm`) is accruing idle CPU against iowait — NOT a disk bottleneck.
- PSI `full` counts ANY TASK_UNINTERRUPTIBLE wait (device PM, ACPI completions, kernel completions) — not just block I/O.
- Load average is only meaningful divided by nproc.
- Always distinguish accounting artefacts from real saturation.

Output structure (terse, no preamble):
1. Verdict: one line — healthy / watch / action.
2. Top findings: up to 3, each one line: metric=value -> interpretation [severity: info|watch|action].
3. Likely root cause (if any) + 1-2 non-destructive next-step commands to investigate further.
4. Suspicious-but-inconclusive (0-3 bullets, optional).

Do not recommend reboots, driver changes, or config changes. Do not pad.'

CLAUDE_ARGS=(-p --append-system-prompt "$SYSTEM_PROMPT")
[[ -n "$MODEL" ]] && CLAUDE_ARGS+=(--model "$MODEL")

{
  echo "Read-only performance snapshot below — diagnose per the instructions."
  echo
  cat "$TMP"
} | claude "${CLAUDE_ARGS[@]}"
