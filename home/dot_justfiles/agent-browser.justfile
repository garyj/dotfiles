# ----------------------
# Agent Browser recipes
# ----------------------
#
# Binary is managed here. The skill itself is installed by chezmoi via
# `.chezmoiexternal.toml.tmpl` into ~/.agents/skills/agent-browser/ and
# symlinked into agent dirs by dot_agents/agent-skills-link.sh.

import "_common.justfile"

# check if agent-browser is installed
@installed:
    command agent-browser > /dev/null && echo "agent-browser is installed" || echo "agent-browser is not installed"

# install agent-browser CLI globally via npm with system dependencies
@install:
    npm install -g agent-browser
    agent-browser install --with-deps
    just --justfile {{ justfile() }} version

# update agent-browser CLI to the latest version
@upgrade:
    just --justfile {{ justfile() }} version
    npm install -g agent-browser
    agent-browser install --with-deps
    just --justfile {{ justfile() }} version

# display agent-browser CLI version
@version:
    command agent-browser --version

# see agent-browser CLI usage
@help:
    command agent-browser --help

# Skill is managed by chezmoi externals — see .chezmoiexternal.toml.tmpl
