---
name: manage-dependencies
description: Use when adding, pinning, or removing a dependency in this chezmoi dotfiles repo. Covers the mise-vs-apt decision, Renovate version pins in .chezmoidata.yaml, the coding-agent 1-day release-age tier, and what removal does and does not uninstall.
---

# Managing dependencies

CLI tools are managed by **mise** (`home/private_dot_config/mise/config.toml.tmpl`); system packages, daemons, and GUI apps stay on **apt**. Pinned tool/external versions are centralized in `home/.chezmoidata.yaml`, where `# renovate:` annotations let Renovate open version-bump PRs.

## Adding a dependency

- CLI dev tool whose apt version lags badly, or that apt lacks → add to mise `[tools]`:
  - low-risk fast-mover → float at `'latest'` (the global `minimum_release_age = "3d"` bakes every release before install)
  - want an audited, PR-reviewed cadence → pin it: add `name: "x.y.z"  # renovate: datasource=github-releases depName=owner/repo` to `.chezmoidata.yaml`, then reference it as `['{{ .tools.name }}']`. Required when the version is reused in more than one file (e.g. worktrunk = mise binary + skill archive).
  - backends are locked to checksummed sources via `disable_backends`; a `github:`/`ubi:` tool must use an explicit backend prefix.
- Stable tool apt handles fine (jq, ripgrep), GUI app, daemon, or system lib → apt list in `run_onchange_before_10_install-packages.sh.tmpl`, or a vendor installer under `.chezmoiscripts/linux/personal/`.

## Coding agents & the 1-day cadence

The AI CLIs (claude, codex, copilot, opencode, gemini, pi) install via mise like any pinned tool but live in their own `coding_agents:` block in `.chezmoidata.yaml`, and get a **1-day** Renovate release-age instead of the 3-day default. That override is a `packageRule` in `renovate.json`, **not** a mise setting: mise's `minimum_release_age` is a no-op on exact-pinned versions (it only bakes floating `'latest'` requests), so the effective freshness gate for a pinned tool is Renovate's `minimumReleaseAge`. The 1-day tier is earned, not automatic: reputable-org tools whose bumps pass under your eyes via the release-notes summarizer before you merge. Grant it to future additions of that calibre; leave slower or less-trusted tools on the 3-day global. codex also needs a `packageRule` with `extractVersion: ^rust-v(?<version>.+)$` because its release tags are `rust-vX.Y.Z`.

## Removing a dependency

Delete its mise line (and its `.chezmoidata.yaml` pin, if any). Removing a package from the apt list does **not** uninstall it; run `sudo apt remove` to actually drop it.

mise tools auto-install on `chezmoi apply` via `run_onchange_after_05_mise-install.sh`.
