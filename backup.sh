#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail
IFS=$'\n\t'

# ---------- CONFIG - EDIT THESE ----------
BACKUP_SRC=( "/mnt/c/Users/user/OneDrive/Desktop" "/etc" )   # paths to back up (array)
BACKUP_DEST="/mnt/c/Users/user/OneDrive/Desktop/backups"              # where archives go
RETENTION_DAYS=14                               # how many days to keep
LOGFILE="$BACKUP_DEST/backup.log"
LOCKFILE="$HOME/.backup_script.lock"
# -----------------------------------------

DRY_RUN=0
if [[ "${1-}" == "--dry-run" ]]; then DRY_RUN=1; fi

# Make sure PATH and required binaries are available for cron
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

log() {
  printf '%s %s\n' "$(date +'%Y-%m-%d %H:%M:%S')" "$*" | tee -a "$LOGFILE"
}

# Ensure destination exists
mkdir -p "$BACKUP_DEST"
touch "$LOGFILE"

# Acquire lock to prevent concurrent runs
exec 9>"$LOCKFILE"
if ! flock -n 9; then
  log "Another backup is already running. Exiting."
  exit 1
fi

USAGE=$(df --output=pcent / | tail -1 | tr -dc '0-9')
if (( USAGE > 80 )); then
    log "Disk usage is at ${USAGE}%, exceeding threshold. Triggering backup."
else
    log "Disk usage is at ${USAGE}%, below threshold. Skipping backup."
    exit 0
fi


# Cleanup on exit
TMPDIR="$(mktemp -d)"
trap 'rc=$?; rm -rf "$TMPDIR"; flock -u 9; exit $rc' EXIT

ARCHIVE_NAME="$(hostname -s)_backup_$(date +'%Y-%m-%d_%H%M%S').tar.gz"
ARCHIVE_PATH="$BACKUP_DEST/$ARCHIVE_NAME"

log "=== Starting backup: $ARCHIVE_NAME ==="
log "Sources: ${BACKUP_SRC[*]}"

if [[ $DRY_RUN -eq 1 ]]; then
  log "(DRY RUN) Would create: $ARCHIVE_PATH"
  exit 0
fi

# Create tar.gz archive
tar -czf "$ARCHIVE_PATH" -- "${BACKUP_SRC[@]}"
log "Archive created: $ARCHIVE_PATH (size: $(du -h "$ARCHIVE_PATH" | cut -f1))"

# Verify archive integrity (list table)
if tar -tf "$ARCHIVE_PATH" > /dev/null; then
  log "Archive verification OK."
else
  log "Archive verification FAILED!"
  exit 2
fi

# Retention: remove old backups
log "Removing backups older than $RETENTION_DAYS days..."
find "$BACKUP_DEST" -maxdepth 1 -type f -name '*.tar.gz' -mtime +"$RETENTION_DAYS" -print -exec rm -f {} \;
log "Old backup cleanup done."

log "=== Backup completed successfully ==="
