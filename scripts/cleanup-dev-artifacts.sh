#!/usr/bin/env bash
set -Eeuo pipefail

YES=0
if [ "${1:-}" = "--yes" ]; then
    YES=1
fi

if [ "$(id -u)" -ne 0 ]; then
    echo "Run as root: sudo $0 [--yes]" >&2
    exit 1
fi

paths=(
    /tmp/abb-testdisk.img
    /tmp/abb-cow.img
    /tmp/cow.img
    /var/tmp/abb-dm-test.img
    /mnt/abb-loop-test
    /mnt/abb-dm-test
    /mnt/abb-scsi-test
    /mnt/abb-restore-test
    /tmp/abb-restore-test
)

echo "This cleanup stops the ABB test daemon and removes known temporary PoC artifacts only."
echo "It does not remove /opt/Synology/ActiveBackupforBusiness, /usr/src/synosnap-0.12.10, or Box64."
echo
echo "Loop devices containing abb in their backing file:"
losetup -a | grep -E 'abb-testdisk|abb' || true
echo
echo "Additional /tmp/abb-*.img candidates:"
find /tmp -maxdepth 1 -type f -name 'abb-*.img' -print 2>/dev/null || true
echo
echo "Fixed test paths:"
for p in "${paths[@]}"; do
    [ -e "$p" ] && echo "$p"
done

echo
echo "Temporary scsi_debug devices:"
lsblk -o NAME,TYPE,SIZE,FSTYPE,LABEL,MOUNTPOINT,MODEL | grep -E 'scsi_debug|abb-scsi|ABBSCSITEST' || true

if [ "$YES" -ne 1 ]; then
    echo
    echo "Dry run only. Re-run with --yes to remove these artifacts."
    exit 0
fi

systemctl stop abb-box64.service 2>/dev/null || true
systemctl unset-environment BOX64_LD_PRELOAD 2>/dev/null || true
pkill -TERM -f synology-backupd 2>/dev/null || true
sleep 3
pkill -KILL -f synology-backupd 2>/dev/null || true

if findmnt -n /mnt/abb-dm-test >/dev/null 2>&1; then
    umount /mnt/abb-dm-test || true
fi
dmsetup remove abbtest 2>/dev/null || true

while IFS= read -r line; do
    loopdev="${line%%:*}"
    backing="$(printf '%s\n' "$line" | sed -n 's/.*(\(.*\)).*/\1/p')"
    case "$backing" in
        /tmp/abb-*|/tmp/*abb*|/var/tmp/abb-*)
            mnt="$(findmnt -n -o TARGET "$loopdev" 2>/dev/null || true)"
            if [ -n "$mnt" ]; then
                umount "$mnt" || true
            fi
            losetup -d "$loopdev" || true
            ;;
    esac
done < <(losetup -a | grep -E 'abb-testdisk|abb' || true)

if [ -f /var/tmp/abb-dm-test.img ]; then
    rm -f /var/tmp/abb-dm-test.img
fi

if findmnt -n /mnt/abb-scsi-test >/dev/null 2>&1; then
    umount /mnt/abb-scsi-test || true
fi
if [ -e /sys/block/sdb/device/model ] && grep -q 'scsi_debug' /sys/block/sdb/device/model 2>/dev/null; then
    echo 1 > /sys/block/sdb/device/delete 2>/dev/null || true
fi
modprobe -r scsi_debug 2>/dev/null || true

for p in /tmp/abb-*.img; do
    [ -e "$p" ] || continue
    case "$p" in
        /tmp/abb-*.img) rm -f "$p" ;;
    esac
done

for p in /tmp/abb-testdisk.img /tmp/abb-cow.img /tmp/cow.img; do
    [ -e "$p" ] && rm -f "$p"
done

for d in /mnt/abb-loop-test /mnt/abb-dm-test /mnt/abb-scsi-test /mnt/abb-restore-test /tmp/abb-restore-test; do
    if [ -d "$d" ]; then
        if findmnt -n "$d" >/dev/null 2>&1; then
            umount "$d" || true
        fi
        rmdir "$d" 2>/dev/null || rm -rf --one-file-system "$d"
    fi
done

echo "Cleanup complete."
