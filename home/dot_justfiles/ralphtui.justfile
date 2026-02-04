# ----------------------
# RalphTui recipes
# https://ralph-tui.com/docs/getting-started/installation
# ----------------------

import "_common.justfile"

# install ralphtui CLI
@install:
    bun install -g ralph-tui
    just --justfile {{ justfile() }} version

# upgrade ralphtui to the latest version
@upgrade:
    just --justfile {{ justfile() }} version
    bun install -g ralph-tui
    just --justfile {{ justfile() }} version

# display ralphtui version
@version:
    ralph-tui --version
