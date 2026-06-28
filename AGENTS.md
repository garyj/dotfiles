# Repository Guidelines

This file provides guidance to AI coding agents working with this repository.

## Repository Overview

This is a chezmoi-based dotfiles repository for managing personal development environment configuration across Linux systems. The source directory is `home/` (set via `.chezmoiroot`).

## Key Chezmoi Commands

```bash
# Bootstrap on new machine
./install.sh

# Common operations
chezmoi apply                    # Apply changes to home directory
chezmoi status                   # Show what would change
chezmoi diff                     # Show diff of pending changes
chezmoi edit <file>              # Edit a managed file
chezmoi add <file>               # Add a file to chezmoi management
chezmoi update                   # Pull and apply latest changes
```

## Architecture

### Machine Detection System

The configuration uses template variables to adapt to different environments:

- **`personal`**: Set to `true` when hostname contains "noodle"
- **`ephemeral`**: Set to `true` for GitHub Codespaces, Docker, Vagrant, VSCode remote containers
- **`headless`**: Set to `true` when no display is available or connected via SSH

These variables are defined in `home/.chezmoi.toml.tmpl` and control which configurations and scripts are applied.

### Directory Structure

```
home/                           # Chezmoi source directory (.chezmoiroot points here)
├── .chezmoiscripts/linux/      # Installation scripts (run_onchange_* pattern)
│   └── personal/               # Scripts only for personal machines
├── .chezmoitemplates/          # Reusable template snippets — {{ template "name" . }}
├── bin/                        # Custom shell scripts and installers
├── private_dot_config/         # XDG config files (~/.config/*)
├── dot_*                       # Dotfiles that go in $HOME
└── *.tmpl                      # Templated files with conditional sections
```

### Vendor apt repo installers

New third-party apt repos go in `home/.chezmoiscripts/linux/personal/` as
`run_onchange_before_install-<name>.sh.tmpl`. Use the `add-apt-repo` helper
(`home/.chezmoitemplates/add-apt-repo`) via `{{ template "add-apt-repo" . }}`
— it handles keyring + sources atomically at the correct 0644 mode. Model
after `install-spotify.sh.tmpl` or `install-dbeaver.sh.tmpl`. Scripts with
extra requirements (debsig-verify, fingerprint checks, codename substitution)
keep their bespoke flow — see `install-onepassword.tmpl`,
`install-browser-firefox-dev.tmpl`, `install-ghostty.sh.tmpl` as exemplars.

Do not add `command -v <binary>` guards in these scripts: `run_onchange_`
already gates on template hash, and a secondary guard silently blocks
legitimate updates (new key URL, changed sources line) from reaching an
already-installed machine.

### Naming Conventions

- `dot_` prefix → `.` in target (e.g., `dot_zshrc` → `.zshrc`)
- `private_` prefix → mode 0600
- `exact_` prefix → remove files not managed by chezmoi
- `.tmpl` suffix → processed as Go template
- `run_onchange_before_*` → scripts that run before apply when content changes
- `run_onchange_after_*` → scripts that run after apply when content changes

### Dependency management

CLI tools are managed by **mise** (`home/private_dot_config/mise/config.toml.tmpl`); system packages, daemons, and GUI apps stay on **apt**. Pinned tool/external versions are centralized in `home/.chezmoidata.yaml`, where `# renovate:` annotations let Renovate open version-bump PRs.

**Adding a dependency:**

- CLI dev tool whose apt version lags badly, or that apt lacks → add to mise `[tools]`:
  - low-risk fast-mover → float at `'latest'` (the global `minimum_release_age = "3d"` bakes every release before install)
  - want an audited, PR-reviewed cadence → pin it: add `name: "x.y.z"  # renovate: datasource=github-releases depName=owner/repo` to `.chezmoidata.yaml`, then reference it as `['{{ .tools.name }}']`. Required when the version is reused in more than one file (e.g. worktrunk = mise binary + skill archive).
  - backends are locked to checksummed sources via `disable_backends`; a `github:`/`ubi:` tool must use an explicit backend prefix.
- Stable tool apt handles fine (jq, ripgrep), GUI app, daemon, or system lib → apt list in `run_onchange_before_10_install-packages.sh.tmpl`, or a vendor installer under `.chezmoiscripts/linux/personal/`.

**Removing a dependency:** delete its mise line (and its `.chezmoidata.yaml` pin, if any). Removing a package from the apt list does **not** uninstall it; run `sudo apt remove` to actually drop it.

mise tools auto-install on `chezmoi apply` via `run_onchange_after_05_mise-install.sh`.

### External Dependencies

External archives and tools are managed via `home/.chezmoiexternal.toml.tmpl`:

- Oh-My-Zsh framework + zsh plugins
- Fonts (Monaspace)
- Shared agent skills (agent-browser, worktrunk, ast-grep, sentry-cli)

### Template Conditionals

Common patterns in `.tmpl` files:

```go
{{- if .personal }}
# Personal machine only config
{{- end }}

{{- if not .headless }}
# GUI environment config
{{- end }}

{{- if lookPath "bat" }}
# Config when bat is installed
{{- end }}
```

## Shell Configuration

Shell config is split across several files:

- `dot_zshrc.tmpl` / `dot_bashrc.tmpl` - Shell-specific config
- `dot_commonrc.tmpl` - Shared configuration for both shells
- `dot_common_alias.tmpl` - All aliases (git, docker, python, etc.)
- `dot_functions` - Shell functions

## File Locations After Apply

Chezmoi manages files that deploy to:

- `~/.config/*` - XDG config (git, starship, atuin, ghostty)
- `~/.local/bin/*` - Custom scripts
- `~/.ssh/*` - SSH configuration
- `~/.*rc` - Shell configuration files

## Coding Style

- Respect existing file formatting; avoid reformatting unless you change content.
- Use `private_` files for secrets; avoid committing real credentials.

## Testing Guidelines

There is no automated test suite. Validate changes with:

- `chezmoi diff` for a safe preview
- `chezmoi apply` on a test machine or container
- Manual execution of affected scripts in `home/.chezmoiscripts/` when relevant

## Commit & Pull Request Guidelines

**Do not commit without explicit approval.** Make the edit, show `git diff --staged` (or `chezmoi diff` when relevant), and wait for the user to say "commit", invoke `/commit`, or otherwise confirm. The user reviews each change before it lands — do not assume a prior "yes" extends to later unrelated edits.

Commit messages typically start with a lowercase verb and colon (e.g., `add: ...`, `update: ...`). Keep them short and action-oriented.

For pull requests, include:

- A brief summary of what changed and why
- Notes about which machine types are affected (e.g., `personal`, `headless`)
- Any manual verification steps you performed
