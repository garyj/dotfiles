# ----------------------
# RalphTui recipes
# https://ralph-tui.com/docs/getting-started/installation
# ----------------------

set dotenv-load := false
set export := true

justfile := justfile_directory() + "/.justfiles/ralphtui.justfile"

# list all available recipes
[private]
@default:
    just --justfile {{ justfile }} --list

# format this justfile
[private]
@fmt:
    just --justfile {{ justfile }} --fmt

# install ralphtui CLI
@install:
    bun install -g ralph-tui
    just --justfile {{ justfile }} version

# upgrade ralphtui to the latest version
@upgrade:
    bun install -g ralph-tui
    just --justfile {{ justfile }} version

# display ralphtui version
@version:
    ralph-tui --version
