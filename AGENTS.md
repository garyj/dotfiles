# Repository Guidelines

Chezmoi dotfiles for personal Linux machines. The source directory is `home/`, set by `.chezmoiroot`. Machine detection
(`personal`, `ephemeral`, `headless`) is defined in `home/.chezmoi.toml.tmpl` and gates most conditionals.

Hard-won machine and tooling findings live in [GOTCHAS.md](GOTCHAS.md). Read it before debugging desktop,
terminal, or Docker networking behaviour; several causes there are already diagnosed and expensive to re-derive.

## Vendor apt repo installers

- Third-party apt repos live in `home/.chezmoiscripts/linux/personal/`.
- Invoke the `add-apt-repo` skill before writing or editing one.

## Dependency management

CLI tools are managed by **mise** (`home/private_dot_config/mise/config.toml.tmpl`); system packages, daemons, and GUI
apps stay on **apt**. Pinned versions are centralized in `home/.chezmoidata.yaml`, where `# renovate:` annotations let
Renovate open version-bump PRs. Invoke the `manage-dependencies` skill before adding, pinning, or removing one.

## Agent config

Instructions and skills for every coding agent live in their own repo, `garyj/dotagents`, cloned to `~/.agents` as a
`git-repo` external. `run_after_40_agents-install.sh` runs its `scripts/install`, which symlinks `~/.claude/CLAUDE.md`,
`~/.codex/AGENTS.md`, and the other global instruction files to `~/.agents/instructions.md`, and the skill stores to
`~/.agents/skills`. Edit agent config there, not here. A saved edit is live without an apply.

Skills that ship with a pinned CLI (agent-browser, sentry-cli, worktrunk) and deps-upgrade-report stay chezmoi
externals, extracted to `~/.local/share/agent-skills/<name>`, and the install links each into `~/.agents/skills`. Adding
one is a stanza in `.chezmoiexternal.toml.tmpl` and a pin in `.chezmoidata.yaml`, nothing in the dotagents repo.

## Shell Configuration

`dot_commonrc.tmpl` loop-sources `~/.config/shell/*.sh`. New aliases go in the matching topic file there, or a new file
for a new topic. `~/.private_alias` is machine-local and unmanaged, sourced last so it can override.

## Coding Style

- Respect existing file formatting; avoid reformatting unless you change content.
- Use `private_` files for secrets; avoid committing real credentials.

## Agent config security

A `prek` pre-commit hook scans every staged text file for hidden Unicode (prompt-injection vectors) via `apm audit`. Run
`prek install` once per clone to enable it; see `.pre-commit-config.yaml` for details.

## Testing Guidelines

There is no automated test suite. Validate changes with:

- `chezmoi diff` for a safe preview
- `chezmoi apply` on a test machine or container
- Manual execution of affected scripts in `home/.chezmoiscripts/` when relevant

The repo-root `justfile` wraps these (`just diff`, `just pc`) and shadows the machine-level
`~/justfile` inside a checkout. Add repo workflows there, not to `home/justfile`, which is a different file for a
different job.

## Commit & Pull Request Guidelines

**Do not commit without explicit approval.** Make the edit, show `git diff --staged` (or `chezmoi diff` when relevant),
and wait for the user to say "commit", invoke `/commit`, or otherwise confirm. The user reviews each change before it
lands, do not assume a prior "yes" extends to later unrelated edits.

Commit messages typically start with a lowercase verb and colon (e.g., `add: ...`, `update: ...`). Keep them short and
action-oriented.

For pull requests, include:

- A brief summary of what changed and why
- Notes about which machine types are affected (e.g., `personal`, `headless`)
- Any manual verification steps you performed
