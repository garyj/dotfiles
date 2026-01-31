# ----------------------
# Agent Browser recipes
# ----------------------

set dotenv-load := false
set export := true

justfile := justfile_directory() + "/agent-browser.justfile"

# list all available recipes
[private]
@default:
    just --justfile {{ justfile }} --list

# format this justfile
[private]
@fmt:
    just --justfile {{ justfile }} --fmt

# check if agent-browser is installed
@installed:
    command agent-browser > /dev/null && echo "agent-browser is installed" || echo "agent-browser is not installed"

# install agent-browser CLI globally via npm with system dependencies
@install:
    npm install -g agent-browser
    agent-browser install --with-deps

# update agent-browser CLI to the latest version
@upgrade:
    just --justfile {{ justfile }} version
    npm install -g agent-browser
    agent-browser install --with-deps
    just --justfile {{ justfile }} version

# display agent-browser CLI version
@version:
    command agent-browser --version

# see agent-browser CLI usage
@help:
    command agent-browser --help

# add agent-browser skill to AI coding assistant
@skill:
    npx --yes skills add vercel-labs/agent-browser

# update agent-browser skill in AI coding assistant
@skill-update:
    npx --yes skills update vercel-labs/agent-browser
