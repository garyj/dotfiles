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

# update a marketplace (or all if no name given)
[group("plugins")]
[script("bash")]
mpup name="":
    command claude plugin marketplace update "{{ name }}"

# list marketplaces
[group("plugins")]
@mpl:
    command claude plugin marketplace list

# install a plugin (renamed from pla)
[no-cd]
[group("plugins")]
@pli plugin *ARGS:
    command claude plugin install "{{ plugin }}" {{ ARGS }}

# update a plugin (or all if no name given)
[no-cd]
[group("plugins")]
[script("bash")]
plup *plugin:
    if [ -z "{{ plugin }}" ]; then
        plugins=$(jq -r '.plugins | keys[]' ~/.claude/plugins/installed_plugins.json 2>/dev/null)
        for p in $plugins; do
            echo "Updating plugin: $p"
            command claude plugin update "$p" || true
        done
    else
        command claude plugin update {{ plugin }}
    fi

# remove/uninstall a plugin (use --scope project|local for scoped plugins)
[no-cd]
[group("plugins")]
@plr plugin *ARGS:
    command claude plugin uninstall "{{ plugin }}" {{ ARGS }}

# disable a plugin (use --scope project|local for scoped plugins)
[no-cd]
[group("plugins")]
@pld plugin *ARGS:
    command claude plugin disable "{{ plugin }}" {{ ARGS }}

# enable a plugin (use --scope project|local for scoped plugins)
[no-cd]
[group("plugins")]
@ple plugin *ARGS:
    command claude plugin enable "{{ plugin }}" {{ ARGS }}

# list installed plugins
[no-cd]
[group("plugins")]
@pll:
    command claude plugin list
