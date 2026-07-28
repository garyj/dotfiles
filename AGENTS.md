# Repository Guidelines

Chezmoi dotfiles for personal Linux machines. The source directory is `home/`, set by `.chezmoiroot`. Machine detection
(`personal`, `ephemeral`, `headless`) is defined in `home/.chezmoi.toml.tmpl` and gates most conditionals.

## Vendor apt repo installers

- Third-party apt repos live in `home/.chezmoiscripts/linux/personal/`.
- Invoke the `add-apt-repo` skill before writing or editing one.

## Dependency management

CLI tools are managed by **mise** (`home/private_dot_config/mise/config.toml.tmpl`); system packages, daemons, and GUI
apps stay on **apt**. Pinned versions are centralized in `home/.chezmoidata.yaml`, where `# renovate:` annotations let
Renovate open version-bump PRs. Invoke the `manage-dependencies` skill before adding, pinning, or removing one.

## Agent config fan-out

All coding agents draw their global instructions from one source, `home/.chezmoitemplates/agents/instructions.md`. Each
agent has a thin wrapper that pulls it in with `{{ includeTemplate "agents/instructions.md" . }}` and renders to that
agent's own filename. Edit the shared body, run `chezmoi apply`, and every agent updates. To give ONE agent extra
instructions, append a section below the include in its wrapper. copilot and cursor read instructions per-repo only, so
they are not in this fan-out.

Skills live once in `~/.agents/skills`. claude and codex read their own `~/.<agent>/skills` dir, so a
`symlink_skills.tmpl` points it at that store. gemini, copilot and pi discover `~/.agents/skills` natively, so their
skills dirs are deliberately left un-symlinked. This is correct; do not "fix" it by adding a symlink (gemini would then
scan the store twice and warn on every skill). opencode has no skills feature.

codex re-creates its hidden `.system/` of built-in skills inside `~/.agents/skills` on next launch. It is dot-prefixed,
so other agents' skill discovery skips it.

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
