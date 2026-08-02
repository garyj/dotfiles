# --------------------
# Claude Code recipes
# --------------------
#
# Binary is managed by mise (aqua:anthropics/claude-code, pinned in
# .chezmoidata.yaml); auth, plugin and marketplace recipes live here.

set quiet := true

import "_common.justfile"

# install or update a marketplace
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
    plugins=$(jq -r '.plugins | keys[] | select(endswith("@{{ name }}")) | split("@")[0]' ~/.claude/plugins/installed_plugins.json 2>/dev/null)
    for plugin in $plugins; do
        echo "Removing plugin: $plugin"
        command claude plugin uninstall "$plugin" 2>&1 || true
    done
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

# install a plugin
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
        # project/local-scoped plugins must be updated from their project dir with --scope
        jq -r '.plugins | to_entries[] | .key as $name | .value[] | [$name, .scope, .projectPath // ""] | @tsv' ~/.claude/plugins/installed_plugins.json 2>/dev/null |
            while IFS=$'\t' read -r name scope path; do
                if [ "$scope" = "user" ]; then
                    echo "Updating plugin: $name"
                    command claude plugin update "$name" || true
                else
                    echo "Skipping $name ($scope scope), update it with:"
                    echo "  cd $path && claude plugin update --scope $scope $name"
                fi
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

# claude-code is pinned in .chezmoidata.yaml (aqua:anthropics/claude-code) - bump it there
@upgrade:
    echo "claude-code is pinned in .chezmoidata.yaml (aqua:anthropics/claude-code); bump the version there"
