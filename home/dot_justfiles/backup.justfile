# ----------------------
# Restic backup recipes
# ----------------------
#
# Thin wrappers over ~/bin/restic-backup (managed by chezmoi). What and where to
# back up is configured in the dotfiles repo at home/.chezmoidata/backup.yaml.

import "_common.justfile"

# --- status ---

# show the timer schedule and the last run's result (default)
[group('status')]
@status:
    systemctl --user list-timers restic-backup.timer --no-pager
    systemctl --user status restic-backup.service --no-pager --lines=0 || true

# show the most recent backup logs (pass a number to change how many lines)
[group('status')]
@logs lines="50":
    journalctl --user -u restic-backup.service -n {{ lines }} --no-pager

# --- local repo (/extra) ---

# run a backup right now (e.g. just before making risky changes)
[group('local')]
@now:
    restic-backup

# list snapshots in the local repo (newest last)
[group('local')]
@snapshots:
    restic-backup snapshots

# restore ONE file from the local backup to /tmp, then diff it against live.
# defaults to ~/.zshrc; pass any path to restore or test another file.
#   j backup::restore-file
#   j backup::restore-file ~/dev/foo/config.toml
[group('local')]
restore-file file="~/.zshrc":
    #!/usr/bin/env bash
    set -euo pipefail
    src="{{ file }}"
    abs=$(realpath -m -- "${src/#\~/$HOME}")
    target="$HOME/tmp/restic-restore"
    rm -rf "$target"
    restic-backup restore latest --target "$target" --include "$abs" >/dev/null
    got="$target$abs"
    [ -e "$got" ] || { echo "not found in the latest snapshot: $abs" >&2; exit 1; }
    echo "restored: $got ($(wc -c <"$got") bytes)"
    if [ -e "$abs" ]; then
      diff -q "$got" "$abs" >/dev/null 2>&1 \
        && echo "matches the live file - restore verified" \
        || echo "differs from live (newer edits since the snapshot)"
    else
      echo "no live file at $abs - copy it back with:  cp '$got' '$abs'"
    fi

# verify local repository integrity
[group('local')]
@check:
    restic-backup check

# mount the local repo read-only to browse and restore files (Ctrl-C to unmount)
[group('local')]
@mount dir="/tmp/restic":
    mkdir -p "{{ dir }}"
    restic-backup mount "{{ dir }}"

# release a mount left behind by a closed terminal or forgotten `mount`
[group('local')]
@unmount dir="/tmp/restic":
    fusermount -u "{{ dir }}"

# --- offsite (Wasabi) ---

# push new snapshots offsite now (also used for the one-time initial seed)
[group('offsite')]
@copy:
    restic-backup copy

# list snapshots in the offsite remote repo
[group('offsite')]
@remote-snapshots:
    restic-backup remote snapshots

# restore ONE file from the OFFSITE (Wasabi) backup to /tmp, then diff vs live.
# defaults to ~/.zshrc; pass any path. Proves the offsite copy is restorable.
#   j backup::remote-restore-file
#   j backup::remote-restore-file ~/dev/foo/config.toml
[group('offsite')]
remote-restore-file file="~/.zshrc":
    #!/usr/bin/env bash
    set -euo pipefail
    src="{{ file }}"
    abs=$(realpath -m -- "${src/#\~/$HOME}")
    target="$HOME/tmp/restic-restore-remote"
    rm -rf "$target"
    restic-backup remote restore latest --target "$target" --include "$abs" >/dev/null
    got="$target$abs"
    [ -e "$got" ] || { echo "not found in the latest offsite snapshot: $abs" >&2; exit 1; }
    echo "restored from Wasabi: $got ($(wc -c <"$got") bytes)"
    if [ -e "$abs" ]; then
      diff -q "$got" "$abs" >/dev/null 2>&1 \
        && echo "matches the live file - offsite restore verified" \
        || echo "differs from live (newer edits since the snapshot)"
    else
      echo "no live file at $abs - copy it back with:  cp '$got' '$abs'"
    fi

# restore from the offsite remote with raw restic args (advanced)
# e.g. j backup::remote-restore "latest --target /tmp/r --include ~/x"
[group('offsite')]
@remote-restore *args:
    restic-backup remote restore {{ args }}

# verify the offsite remote repo's integrity
[group('offsite')]
@remote-check:
    restic-backup remote check

# --- maintenance (both repos) ---

# reclaim disk space from unreferenced data, locally then offsite (heavier; run occasionally)
[group('maintenance')]
@prune:
    restic-backup prune
    restic-backup remote prune

# --- meta ---

# backups are provisioned by chezmoi (binary, repo, timer) - nothing to install here
[group('meta')]
@install:
    echo "restic backup is managed by chezmoi; nothing to install via just"

# restic is pinned in .chezmoidata.yaml (github_bins.restic) - bump it there
[group('meta')]
@upgrade:
    echo "restic is pinned in .chezmoidata.yaml (github_bins.restic); bump the version there"
