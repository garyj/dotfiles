# /// script
# requires-python = ">=3.11"
# dependencies = ["anthropic>=0.40"]
# ///
"""Summarize a Renovate PR's release notes into a short, garyj-tailored comment.

Runs in CI from the renovate-summary workflow. Reads the PR body (which Renovate
fills with the upstream release notes), asks Claude for a TL;DR tailored to
garyj's stack (see .github/release-summary-context.md), and posts/updates a
single comment on the PR via gh. One Claude call, no streaming, no tools.
"""

from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path

import anthropic

MARKER = "<!-- deps-summary -->"
CONTEXT_FILE = Path(".github/release-summary-context.md")


def gh(*args: str) -> subprocess.CompletedProcess:
    return subprocess.run(["gh", *args], capture_output=True, text=True)


def main() -> int:
    repo = os.environ["REPO"]
    pr = os.environ["PR_NUMBER"]
    title = os.environ.get("PR_TITLE", "")
    body = os.environ.get("PR_BODY", "")
    model = os.environ.get("CLAUDE_MODEL", "claude-sonnet-5")

    if not body.strip():
        print("PR body is empty; nothing to summarize.")
        return 0

    # Prefer a private RELEASE_SUMMARY_CONTEXT variable (kept out of this public
    # repo); fall back to the committed generic file if it exists.
    context = os.environ.get("RELEASE_SUMMARY_CONTEXT", "").strip()
    if not context and CONTEXT_FILE.exists():
        context = CONTEXT_FILE.read_text()
    system = (
        "You write a short release-notes TL;DR for garyj on the dependency-update "
        "PRs in his dotfiles repo. Tailor what you surface to who he is:\n\n"
        f"{context}\n\n"
        "Rules:\n"
        "- Output GitHub-flavored markdown, no preamble, starting with the heading "
        "`### TL;DR for garyj`.\n"
        "- 3-6 bullets max. Lead with what matters to him: breaking changes, security "
        "fixes, and new features he'd actually use given his stack. Skip marketing, "
        "trivia, and platform notes irrelevant to Linux.\n"
        "- If something needs action (a breaking change or migration), call it out "
        "first in **bold**.\n"
        "- If the notes are thin or purely internal, say so in one line rather than "
        "padding.\n"
        "- Be concise and concrete; assume he knows these tools. No em-dashes."
    )

    client = anthropic.Anthropic()  # reads ANTHROPIC_API_KEY from the environment
    try:
        response = client.messages.create(
            model=model,
            max_tokens=1500,
            system=system,
            messages=[{"role": "user", "content": f"PR: {title}\n\nRelease notes:\n\n{body[:60000]}"}],
        )
    except anthropic.APIStatusError as exc:
        # Log enough to diagnose; soft-skip transient throttles/5xx, surface the rest.
        retry_after = None
        try:
            retry_after = exc.response.headers.get("retry-after")
        except Exception:
            pass
        print(f"API error: status={exc.status_code} request_id={getattr(exc, 'request_id', None)} retry-after={retry_after}")
        print(f"detail: {str(exc)[:500]}")
        if isinstance(exc, anthropic.RateLimitError) or (exc.status_code or 0) >= 500:
            print("Transient; skipping summary. Re-add the deps-summary label to retry.")
            return 0
        raise
    summary = "".join(b.text for b in response.content if b.type == "text").strip()
    if not summary:
        print("Model returned no text; skipping.")
        return 0

    comment = (
        f"{MARKER}\n{summary}\n\n"
        f"<sub>Auto-summarized by `{model}` from the release notes above. "
        "Add/remove the `deps-summary` label to control this.</sub>"
    )

    if "--dry-run" in sys.argv:
        print(comment)
        return 0

    # Idempotent: update the existing summary comment if present, else create one.
    found = gh(
        "api", f"repos/{repo}/issues/{pr}/comments",
        "--jq", f'[.[] | select(.body | contains("{MARKER}")) | .id] | first // empty',
    )
    comment_id = found.stdout.strip()
    if comment_id:
        result = gh(
            "api", "--method", "PATCH",
            f"repos/{repo}/issues/comments/{comment_id}", "-f", f"body={comment}",
        )
        action = "updated"
    else:
        result = gh("pr", "comment", pr, "--repo", repo, "--body", comment)
        action = "created"

    if result.returncode != 0:
        print(result.stderr, file=sys.stderr)
        return 1
    print(f"Summary comment {action}.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
