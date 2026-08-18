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

One shared instruction body (`home/.chezmoitemplates/agents/instructions.md`) and one skill store (`~/.agents/skills`)
feed every coding agent. Each agent's wrapper pulls the body in with `{{ includeTemplate "agents/instructions.md" . }}`
and renders to that agent's own filename; edit the body, run `chezmoi apply`, and every agent updates. To give ONE
agent extra instructions, append a section below the include in its wrapper. `~/.agents/AGENTS.md` is the same body,
the canonical copy.

| Agent    | Instructions                                       | Skills                                             |
| -------- | -------------------------------------------------- | -------------------------------------------------- |
| claude   | wrapper → `~/.claude/CLAUDE.md`                    | `symlink_skills.tmpl` → `~/.claude/skills`         |
| codex    | wrapper → `~/.codex/AGENTS.md`                     | `symlink_skills.tmpl` → `~/.codex/skills`          |
| gemini   | wrapper → `~/.gemini/GEMINI.md`                    | scans `~/.agents/skills` natively                  |
| pi       | wrapper → `~/.pi/agent/AGENTS.md`                  | scans `~/.agents/skills` natively                  |
| opencode | wrapper → `~/.config/opencode/AGENTS.md`           | no skills feature                                  |
| grok     | claude's `~/.claude/CLAUDE.md` via its compat scan | claude's `~/.claude/skills` via its compat scan    |
| copilot  | per-repo only, not in the fan-out                  | scans `~/.agents/skills` natively                  |
| cursor   | per-repo only, not in the fan-out                  | not managed here                                   |

Traps. Each of these looks like a gap but is deliberate:

- gemini/copilot/pi skills dirs are left un-symlinked on purpose. Do not "fix" this: gemini would scan the store twice
  and warn on every skill.
- grok gets NO wrapper and NO symlink on purpose. Its Claude Code compat scan (no off switch) already loads the
  user-global `~/.claude/CLAUDE.md` and `~/.claude/skills`; adding a `~/.grok/AGENTS.md` or `~/.grok/skills` makes it
  load the instructions twice / scan the store twice. The user-global rules load is undocumented in grok's README;
  verified live 2026-08-15 in its session `prompt_context.json`.
- grok truncates each rules file at 10,000 characters and `~/.claude/CLAUDE.md` sits at 9.9k, so growing the shared
  body or claude's extras clips grok's copy (grok warns when it does).
- codex re-creates its hidden `.system/` of built-in skills inside `~/.agents/skills` on next launch. It is
  dot-prefixed, so other agents' skill discovery skips it.

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
