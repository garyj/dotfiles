#!/bin/bash
# A chezmoi-rendered ~/.agents blocks the git-repo external's clone, so move it aside.
set -euo pipefail
agents="$HOME/.agents"
if [ ! -d "$agents" ] || [ -d "$agents/.git" ]; then
    exit 0
fi
mv "$agents" "$agents.old"
# The rendered wrappers are copies of the old body; scripts/install refuses to replace real files.
for f in "$HOME/.claude/CLAUDE.md" "$HOME/.codex/AGENTS.md" "$HOME/.gemini/GEMINI.md" \
         "$HOME/.pi/agent/AGENTS.md" "$HOME/.config/opencode/AGENTS.md"; do
    if [ -f "$f" ] && [ ! -L "$f" ] && cmp -s "$f" "$agents.old/AGENTS.md"; then
        rm "$f"
    fi
done
