# ----------------------
# Copilot recipes
# ----------------------

import "_common.justfile"

# open Copilot configuration file in Sublime Text
@config:
    command copilot --config

# check for outdated Copilot npm package
@outdated:
    npm outdated @github/copilot || true

# install Copilot CLI globally via npm
@install:
    npm install -g @github/copilot
    just --justfile {{ justfile() }} version

# update Copilot CLI to the latest version
@upgrade:
    just --justfile {{ justfile() }} version
    npm install -g @github/copilot
    just --justfile {{ justfile() }} version

# display Copilot CLI version
@version:
    command copilot --version
