#!/bin/sh
# ============================================================
# rpi-fs-expand — grow the root partition/filesystem to the card size
# ============================================================
# The .wic image has a fixed rootfs, so a 32/64 GB SD card boots with only a
# few GB usable. Run once (the service is guarded by a flag) and grow both the
# partition table entry and the ext4 filesystem. resize2fs grows a *mounted*
# ext4 online, so no reboot is needed.
# ============================================================

set -eu

FLAG="/var/lib/rpi-fs-expanded"

if [ -e "${FLAG}" ]; then
    echo "rpi-fs-expand: already expanded (${FLAG} present)"
    exit 0
fi

# Root device, e.g. /dev/mmcblk0p2 or /dev/sda2.
ROOT_SRC=$(awk '$2 == "/" { print $1; exit }' /proc/mounts)
if [ -z "${ROOT_SRC}" ] || [ ! -b "${ROOT_SRC}" ]; then
    echo "rpi-fs-expand: cannot determine root block device (root=${ROOT_SRC:-none})"
    exit 0
fi

# Do not touch network/loop/virtual roots -- only real disks (mmcblk, sd*, nvme).
case "${ROOT_SRC}" in
    /dev/mmcblk*|/dev/sd*|/dev/nvme*|/dev/vd*|/dev/hd*) ;;
    *)
        echo "rpi-fs-expand: ${ROOT_SRC} is not a supported root device, skipping"
        touch "${FLAG}"
        exit 0
        ;;
esac

DISK=$(echo "${ROOT_SRC}" | sed -E 's/p?[0-9]+$//')
PART=$(echo "${ROOT_SRC}" | sed -E 's/^.*p?([0-9]+)$/\1/')

echo "rpi-fs-expand: growing ${DISK} partition ${PART} (${ROOT_SRC})"

# growpart exits non-zero when there is nothing left to grow -- that is a
# success for us (card already fully used).
if ! growpart "${DISK}" "${PART}"; then
    echo "rpi-fs-expand: growpart reported no change (partition already at end of disk)"
fi

# Re-read the partition table so the kernel sees the new size before resizing.
partx -u "${ROOT_SRC}" 2>/dev/null || blockdev --rereadpt "${DISK}" 2>/dev/null || true

if resize2fs "${ROOT_SRC}"; then
    echo "rpi-fs-expand: filesystem grown"
else
    echo "rpi-fs-expand: WARN: resize2fs failed; leaving flag unset to retry next boot"
    exit 0
fi

df -h / || true
touch "${FLAG}"
echo "rpi-fs-expand: done"
