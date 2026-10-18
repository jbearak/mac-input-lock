#!/bin/sh
set -eu
project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
source_app="$project_dir/dist/Mac Input Lock.app"
applications_dir=${1:-/Applications}
destination="$applications_dir/Mac Input Lock.app"
test -d "$source_app" || { echo "Build the app first with ./Scripts/build-app.sh" >&2; exit 1; }
codesign --verify --deep --strict "$source_app"
mkdir -p "$applications_dir"
stage_dir=$(mktemp -d "$applications_dir/.mac-input-lock.XXXXXX")
trap 'rm -rf "$stage_dir"' EXIT INT TERM
ditto "$source_app" "$stage_dir/Mac Input Lock.app"
codesign --verify --deep --strict "$stage_dir/Mac Input Lock.app"
# Quitting releases any active event tap before replacing the running app.
pkill -U "$(id -u)" -x MacInputLock || [ "$?" -eq 1 ]
remaining=50
while pgrep -U "$(id -u)" -x MacInputLock >/dev/null; do
    remaining=$((remaining - 1))
    if [ "$remaining" -eq 0 ]; then
        echo "Mac Input Lock is still quitting. Try again in a moment." >&2
        exit 1
    fi
    sleep 0.1
done
if [ -e "$destination" ]; then
    backup_dir=$(mktemp -d "${TMPDIR:-/tmp}/mac-input-lock-backup.XXXXXX")
    mv "$destination" "$backup_dir/Mac Input Lock.app"
    echo "Previous app: $backup_dir/Mac Input Lock.app"
fi
if ! mv "$stage_dir/Mac Input Lock.app" "$destination"; then
    if [ -n "${backup_dir:-}" ]; then
        mv "$backup_dir/Mac Input Lock.app" "$destination"
    fi
    exit 1
fi
open "$destination"
echo "Installed $destination"
