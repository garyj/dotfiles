# Release-summary tailoring

Fed to the release-notes summarizer so it surfaces what's relevant. Kept
deliberately generic, this repo is public. For richer, private tailoring,
set a `RELEASE_SUMMARY_CONTEXT` repository variable (see the workflow); the
script prefers it over this file, so personal detail never lands in git.

## Reader profile

A senior engineer working mostly in **Python** (some TypeScript), on **Linux**.
Typical surface: web frameworks and async services, SQL and NoSQL databases,
containerized deploys, CI, and the Anthropic Claude API. Tooling leans modern
(uv, ruff, pytest).

## What to surface

- Lead with breaking changes and required migrations, security fixes / CVEs, and
  new features relevant to a modern Python web / data / DevOps stack on Linux.
- Also call out genuinely interesting or novel things worth learning, even if not
  strictly actionable: a clever new capability, a useful technique, or anything a
  senior engineer would find cool. Keep it to around five, after the actionable
  items, so the TL;DR stays tight.
- Skip marketing, contributor shout-outs, version-bump noise, and notes specific
  to non-Linux platforms unless they affect cross-platform behavior.
- Be concrete and technical; assume the reader knows these tools. No em-dashes.
