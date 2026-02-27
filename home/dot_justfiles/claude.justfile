# --------------------
# Claude Code recipes
# --------------------

set quiet := true

import "_common.justfile"

# BUN_CONFIG_DISABLE_COPY_FILE_RANGE for encryptfs otherwise the install fails
# https://github.com/anthropics/claude-code/issues/8158

# install Claude Code CLI
[script("bash")]
install:
    export BUN_CONFIG_DISABLE_COPY_FILE_RANGE=true
    curl -fsSL https://claude.ai/install.sh | bash
    just --justfile {{ justfile() }} version

# update Claude Code
[script("bash")]
upgrade:
    export BUN_CONFIG_DISABLE_COPY_FILE_RANGE=true
    just --justfile {{ justfile() }} version
    command claude update
    just --justfile {{ justfile() }} version

# see Claude Code API/CLI usage
@usage:
    bunx ccusage@latest

# show Claude Code CLI version
@version:
    command claude --version

# install or update a marketplace (renamed from mpa)
[group("plugins")]
[script("bash")]
mpi url:
    output=$(command claude plugin marketplace add "{{ url }}" 2>&1)
    if echo "$output" | grep -qi "already installed"; then
        name=$(echo "$output" | sed -n "s/.*Marketplace '\([^']*\)'.*/\1/p")
        echo "Already installed, will update instead: $name"
        command claude plugin marketplace update "$name"
    else
        echo "$output"
    fi

# remove a marketplace (and its plugins)
[group("plugins")]
[script("bash")]
mpr name:
    # Find and remove all plugins from this marketplace
    plugins=$(jq -r '.plugins | keys[] | select(endswith("@{{ name }}")) | split("@")[0]' ~/.claude/plugins/installed_plugins.json 2>/dev/null)
    for plugin in $plugins; do
        echo "Removing plugin: $plugin"
        command claude plugin uninstall "$plugin" 2>&1 || true
    done
    # Remove the marketplace
    command claude plugin marketplace remove "{{ name }}"

# update a marketplace
[group("plugins")]
@mpup name:
    command claude plugin marketplace update "{{ name }}"

# list marketplaces
[group("plugins")]
@mpl:
    command claude plugin marketplace list

# install a plugin (renamed from pla)
[group("plugins")]
@pli plugin *ARGS:
    command claude plugin install "{{ plugin }}" {{ ARGS }}

# update a plugin
[group("plugins")]
@plup plugin *ARGS:
    command claude plugin update "{{ plugin }}" {{ ARGS }}

# remove/uninstall a plugin
[group("plugins")]
@plr plugin:
    command claude plugin uninstall "{{ plugin }}"

# disable a plugin
[group("plugins")]
@pld plugin:
    command claude plugin disable "{{ plugin }}"

# enable a plugin
[group("plugins")]
@ple plugin:
    command claude plugin enable "{{ plugin }}"

# list installed plugins
[group("plugins")]
@pll:
    # why is there no `claude plugin list`? :(
    jq -r '.plugins | keys[] | split("@") | "\(.[0]) (from \(.[1]))"' ~/.claude/plugins/installed_plugins.json
