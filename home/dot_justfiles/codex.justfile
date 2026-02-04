# ----------------------
# Codex recipes
# ----------------------

import "_common.justfile"

# open Codex configuration file in Sublime Text
@config:
    command codex --config

# check for outdated Codex npm package
@outdated:
    npm outdated @openai/codex || true

# install Codex CLI globally via npm
@install:
    npm install -g @openai/codex
    just --justfile {{ justfile() }} version

# update Codex CLI to the latest version
@upgrade:
    just --justfile {{ justfile() }} version
    npm install -g @openai/codex
    just --justfile {{ justfile() }} version

# see Codex CLI usage
@usage:
    bunx @ccusage/codex@latest

# display Codex CLI version
@version:
    command codex --version
