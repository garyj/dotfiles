# ----------------------
# Claude Desktop recipes
# ----------------------

set dotenv-load := false
set export := true

justfile := justfile_directory() + "/.justfiles/claude.justfile"

# list all available recipes
[private]
@default:
    just --justfile {{ justfile }} --list

# format this justfile
[private]
@fmt:
    just --justfile {{ justfile }} --fmt


# BUN_CONFIG_DISABLE_COPY_FILE_RANGE for encryptfs otherwise the install fails
# https://github.com/anthropics/claude-code/issues/8158

# install Claude Code CLI
@install:
    #!/usr/bin/env bash
    export BUN_CONFIG_DISABLE_COPY_FILE_RANGE=true
    curl -fsSL https://claude.ai/install.sh | bash
    just --justfile {{ justfile }} version

# update Claude Code
@upgrade:
    #!/usr/bin/env bash
    export BUN_CONFIG_DISABLE_COPY_FILE_RANGE=true
    command claude update
    just --justfile {{ justfile }} version

# see Claude Code API/CLI usage
@usage:
    bunx ccusage@latest

# show Claude Code CLI version
@version:
    command claude --version
