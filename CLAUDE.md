# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

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
├── bin/                        # Custom shell scripts and installers
├── private_dot_config/         # XDG config files (~/.config/*)
├── dot_*                       # Dotfiles that go in $HOME
└── *.tmpl                      # Templated files with conditional sections
```

### Naming Conventions

- `dot_` prefix → `.` in target (e.g., `dot_zshrc` → `.zshrc`)
- `private_` prefix → mode 0600
- `exact_` prefix → remove files not managed by chezmoi
- `.tmpl` suffix → processed as Go template
- `run_onchange_before_*` → scripts that run before apply when content changes
- `run_onchange_after_*` → scripts that run after apply when content changes

### Version Configuration

Language/tool versions are centralized in `home/.chezmoidata.yaml`:

### External Dependencies

External archives and tools are managed via `home/.chezmoiexternal.toml.tmpl`:

- Oh-My-Zsh framework
- Fonts (Monaspace)
- CLI tools (glow)

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
