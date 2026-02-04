# ----------------------
# Gemini recipes
# ----------------------

import "_common.justfile"

# check for outdated Gemini npm package
@outdated:
    npm outdated @google/gemini-cli@latest || true

# install Gemini CLI globally via npm
@install:
    npm install -g @google/gemini-cli@latest
    just --justfile {{ justfile() }} version

# update Gemini CLI to the latest version
@upgrade:
    just --justfile {{ justfile() }} version
    npm install -g @google/gemini-cli@latest
    just --justfile {{ justfile() }} version

# display Gemini CLI version
@version:
    command gemini --version
