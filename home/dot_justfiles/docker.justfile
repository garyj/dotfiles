# ----------------------
# Docker disk hygiene
# ----------------------
#
# Compose derives its project name from the directory name, so every worktree
# gets its own set of postgres/mongo/redis volumes and they outlive the worktree
# that created them. A blanket volume prune cannot tell those from a dev
# database still worth keeping, which is what `report` is for.

import "_common.justfile"

# --- status ---

# what docker is holding on disk (default)
[group('status')]
@status:
    docker system df

# unused volumes grouped by compose project, largest first, with the project directory if it still exists
[group('status')]
report roots="~/dev ~/cowork ~/tries ~/tmp":
    #!/usr/bin/env bash
    set -euo pipefail
    read -ra given <<< {{ quote(roots) }}
    search=()
    for r in "${given[@]}"; do
      r="${r/#\~/$HOME}"
      [ -d "$r" ] && search+=("$r")
    done

    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT
    docker system df -v --format json | jq '.Volumes' > "$tmp/sizes.json"
    docker volume ls -q | xargs -r docker volume inspect > "$tmp/meta.json"

    index=$(find "${search[@]}" -maxdepth 6 \( -name node_modules -o -name .venv \) -prune -o \
      -name .git -printf '%h\n' 2>/dev/null \
      | sed -E 's#^(.*/)([^/]+)$#\2\t\1\2#' | sort -u -k1,1)

    jq -r -n --slurpfile s "$tmp/sizes.json" --slurpfile m "$tmp/meta.json" '
      def tobytes:
        (capture("^(?<n>[0-9.]+)\\s*(?<u>[A-Za-z]*)$") // {n:"0",u:"B"})
        | (.n|tonumber) * ({"B":1,"kB":1000,"MB":1000000,"GB":1000000000,"TB":1000000000000}[.u] // 1);
      ($m[0] | map({key:.Name, value:.}) | from_entries) as $byname
      | $s[0]
      | map(select(.Links == "0"))
      | map({
          project: ($byname[.Name].Labels["com.docker.compose.project"]
                    // (if ($byname[.Name].Labels | has("com.docker.volume.anonymous"))
                        then "(anonymous)" else "(unlabelled)" end)),
          bytes: (.Size | tobytes),
          created: ($byname[.Name].CreatedAt // "")
        })
      | group_by(.project)
      | map({project: .[0].project, vols: length,
             bytes: (map(.bytes) | add),
             created: (map(.created) | sort | .[0] | .[0:10])})
      | sort_by(-.bytes)
      | .[] | [.project, .vols, .bytes, .created] | @tsv
    ' | {
      printf 'PROJECT\tVOLS\tSIZE\tOLDEST\tDIRECTORY\n'
      total=0
      while IFS=$'\t' read -r project vols bytes created; do
        total=$((total + ${bytes%.*}))
        dir=$(awk -F'\t' -v p="$project" '$1 == p {print $2; exit}' <<<"$index")
        printf '%s\t%s\t%s\t%s\t%s\n' \
          "$project" "$vols" "$(numfmt --to=si --suffix=B "${bytes%.*}")" "$created" "${dir/#$HOME/\~}"
      done
      printf '\t\t\t\t\n'
      printf 'TOTAL RECLAIMABLE\t\t%s\t\t\n' "$(numfmt --to=si --suffix=B "$total")"
    } | column -t -s $'\t'

# --- reclaim (rebuildable only, never volume data) ---

# delete stopped containers, leaving images and build cache alone
[group('reclaim')]
@clean-containers:
    docker container prune --force

# delete the whole build cache
[group('reclaim')]
@clean-cache:
    docker builder prune --all --force

# delete every image no container references
[group('reclaim')]
@clean-images:
    docker image prune --all --force

# delete stopped containers, unused images, build cache and networks
[group('reclaim')]
@clean-all:
    docker container prune --force
    docker network prune --force
    docker image prune --all --force
    docker builder prune --all --force
    docker system df

# --- volumes (deletes data) ---

# delete anonymous volumes, which no compose file ever names
[group('volumes')]
@anon:
    docker volume prune --force
    docker system df

# delete every unused volume belonging to ONE compose project, listed first for confirmation
[group('volumes')]
project name:
    #!/usr/bin/env bash
    set -euo pipefail
    mapfile -t vols < <(docker volume ls -q -f dangling=true -f label=com.docker.compose.project={{ quote(name) }})
    [ ${#vols[@]} -gt 0 ] || { echo "no unused volumes for compose project '{{ name }}'"; exit 0; }
    printf '%s\n' "${vols[@]}"
    read -rp "delete these ${#vols[@]} volumes? [y/N] " reply
    [[ $reply == [yY] ]] || { echo "aborted"; exit 0; }
    docker volume rm "${vols[@]}"

# --- meta ---

# docker engine is installed by chezmoi from the vendor apt repo
[group('meta')]
@install:
    echo "docker is installed by chezmoi (run_onchange_before_install-docker.sh); nothing to install via just"

# docker engine tracks the vendor apt repo
[group('meta')]
@upgrade:
    echo "docker engine upgrades with apt from the vendor repo; nothing to upgrade via just"
