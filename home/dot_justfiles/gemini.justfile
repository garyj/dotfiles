# ----------------------
# Gemini recipes
# ----------------------

set dotenv-load := false
set export := true

justfile := justfile_directory() + "/gemini.justfile"

# list all available recipes
[private]
@default:
    just --justfile {{ justfile }} --list

# format this justfile
[private]
@fmt:
    just --justfile {{ justfile }} --fmt

# check for outdated Gemini npm package
@outdated:
    npm outdated @google/gemini-cli@latest

# install Gemini CLI globally via npm
@install:
    npm install -g @google/gemini-cli@latest
    just --justfile {{ justfile }} version

# update Gemini CLI to the latest version
@upgrade:
    just --justfile {{ justfile }} version
    npm install -g @google/gemini-cli@latest
    just --justfile {{ justfile }} version

# display Gemini CLI version
@version:
    command gemini --version
