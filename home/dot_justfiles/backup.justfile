# ----------------------
# Restic backup recipes
# ----------------------
#
# Thin wrappers over ~/bin/restic-backup (managed by chezmoi). What and where to
# back up is configured in the dotfiles repo at home/.chezmoidata/backup.yaml.

import "_common.justfile"

# show the timer schedule and the last run's result (default)
@status:
    systemctl --user list-timers restic-backup.timer --no-pager
    systemctl --user status restic-backup.service --no-pager --lines=0 || true

# run a backup right now (e.g. just before making risky changes)
@now:
    restic-backup

# list snapshots in the repo (newest last)
@snapshots:
    restic-backup snapshots

# show the most recent backup logs (pass a number to change how many lines)
@logs lines="50":
    journalctl --user -u restic-backup.service -n {{ lines }} --no-pager

# reclaim disk space from unreferenced data (heavier; run occasionally)
@prune:
    restic-backup prune

# verify repository integrity
@check:
    restic-backup check

# mount the repo read-only to browse and restore files (Ctrl-C to unmount)
@mount dir="/tmp/restic":
    mkdir -p "{{ dir }}"
    restic-backup mount "{{ dir }}"

# backups are provisioned by chezmoi (binary, repo, timer) - nothing to install here
@install:
    echo "restic backup is managed by chezmoi; nothing to install via just"

# restic is pinned in .chezmoidata.yaml (github_bins.restic) - bump it there
@upgrade:
    echo "restic is pinned in .chezmoidata.yaml (github_bins.restic); bump version+sha there"
