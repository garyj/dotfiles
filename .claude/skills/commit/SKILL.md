---
name: commit
description: Commit for dotfiles changes using the chezmoi repo's convention (add/update/fix/cut with optional scope). Use when committing in the chezmoi dotfiles repository.
---

# Dotfiles Commit

Create a commit for chezmoi dotfiles changes: $ARGUMENTS

## Current Repository State

- Git status: !`git status --porcelain`
- Current branch: !`git branch --show-current`
- Staged changes: !`git diff --cached --stat`
- Unstaged changes: !`git diff --stat`
- Recent commits: !`git log --oneline -10`

## Commit Format

```
<verb>(<scope>): <description>
```

### Verbs

Pick the verb that best describes the change:

- **add**: new config, new tool, new script, new alias, new keybinding
- **update**: modify existing config, change settings, tweak behavior
- **fix**: correct something broken, fix a bug in a script or template
- **cut**: remove config, disable a tool, delete a script or alias

### Scope

- Use `(debian)` when the change is specific to the Debian/GNOME/Wayland migration or GNOME-only config
- Omit the scope when the change is general or applies across all machines
- Other scopes are fine if they clearly describe a platform or area (e.g., `(ssh)`, `(git)`)

### Description

- Lowercase, no period at the end
- Short and action-oriented — describe what changed, not why
- Start with a noun or the thing being changed (e.g., "bringme.sh window matching", "alt-tab to current workspace only")

## Rules

1. If no files are staged, stage all modified and new files automatically
2. Do NOT split into multiple commits — dotfiles changes are typically one logical unit
3. Do NOT add a commit body unless the user specifically asks for one
4. Do NOT run pre-commit checks — there are none in this repo
5. Do NOT push unless the user asks — just commit
6. Always review the diff to pick the right verb and scope
7. Do NOT add a Co-Authored-By line or any AI attribution to the commit message

## Examples

From this repo's history:

```
add(debian): swappy screenshot+annotate workflow replacing flameshot on Wayland
update(debian): bringme.sh and move-to-workspace.sh to use window-tools D-Bus extension
fix(debian): use chezmoi.homeDir template for GNOME shortcut paths
cut(debian): remove tools not available on debian
add: alias/function to copy the full file path to clipboard
update: ghostty config
fix: uv update command
cut: temporary remove stripecli is causing installation issues
add: pyright to uv tools
update: add new ls and ssh password alias + cleanup some old aliases
```
