#!/bin/bash
# Automatic disk mounting script with multi-filesystem support
# Based on SteamOS automount with btrfs enhancements

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions
if [[ -f "${SCRIPT_DIR}/common-functions" ]]; then
    source "${SCRIPT_DIR}/common-functions"
fi

# Load configuration
CONFIG_FILE="/etc/default/automount-config"
if [[ -f "${CONFIG_FILE}" ]]; then
    source "${CONFIG_FILE}"
fi

# Usage information
usage() {
    echo "Usage: $0 <add|remove> <device>"
    echo "  add    - Mount the device"
    echo "  remove - Unmount the device"
}

# Validate arguments
if [[ $# -ne 2 ]]; then
    usage
    exit 1
fi

ACTION=$1
DEVBASE=$2
DEVICE="/dev/${DEVBASE}"

# Get user UID/GID from config or use defaults
DECK_UID="${AUTOMOUNT_UID:-1000}"
DECK_GID="${AUTOMOUNT_GID:-1000}"
LOCK_DIR="/run/lock/automount"
DEVICE_LOCK_WAIT="${AUTOMOUNT_DEVICE_LOCK_WAIT:-20}"
GLOBAL_LOCK_WAIT="${AUTOMOUNT_GLOBAL_LOCK_WAIT:-60}"

mkdir -p "${LOCK_DIR}"

acquire_device_lock() {
    local lock_file="${LOCK_DIR}/device-${DEVBASE}.lock"

    exec 9>"${lock_file}"
    if ! flock -e -w "${DEVICE_LOCK_WAIT}" 9; then
        echo "Error: Timed out waiting for device lock on ${DEVICE}" >&2
        exit 1
    fi
}

with_global_lock() {
    local lock_name="$1"
    local lock_wait="$2"
    shift 2

    (
        exec 8>"${LOCK_DIR}/${lock_name}.lock"
        if ! flock -e -w "${lock_wait}" 8; then
            echo "Error: Timed out waiting for global lock '${lock_name}'" >&2
            exit 1
        fi
        "$@"
    )
}

ensure_filesystem_registered_impl() {
    local fs_name="$1"

    if [[ ! -f /etc/filesystems ]] || ! grep -qxF "${fs_name}" /etc/filesystems; then
        echo "${fs_name}" >> /etc/filesystems
    fi
}

ensure_filesystem_registered() {
    local fs_name="$1"

    with_global_lock "filesystems" "${GLOBAL_LOCK_WAIT}" \
        ensure_filesystem_registered_impl "${fs_name}"
}

mount_with_temporary_udisks_options() {
    local fstype="$1"
    local allow_opts="$2"
    local mount_opts="$3"
    local udisks2_mount_options_conf='/etc/udisks2/mount_options.conf'
    local mount_point

    mkdir -p "$(dirname "${udisks2_mount_options_conf}")"

    if [[ -f "${udisks2_mount_options_conf}" ]] && [[ ! -f "${udisks2_mount_options_conf}.orig" ]]; then
        mv -f "${udisks2_mount_options_conf}"{,.orig}
    fi

    printf "[defaults]\n%s_allow=%s,%s\n" \
        "${fstype}" "${allow_opts}" "${mount_opts}" > "${udisks2_mount_options_conf}"

    mount_point=$(make_dbus_udisks_call call 'data[0]' s \
                                     "block_devices/${DEVBASE}" \
                                     Filesystem Mount \
                                     'a{sv}' 4 \
                                     as-user s "$(getent passwd "${DECK_UID}" | cut -d: -f1)" \
                                     auth.no_user_interaction b true \
                                     fstype s "${fstype}" \
                                     options s "${mount_opts}")
    local status=$?

    rm -f "${udisks2_mount_options_conf}"
    if [[ -f "${udisks2_mount_options_conf}.orig" ]]; then
        mv -f "${udisks2_mount_options_conf}"{.orig,}
    fi

    if (( status != 0 )); then
        return "${status}"
    fi

    printf "%s\n" "${mount_point}"
}

acquire_device_lock

# Mount function
do_mount() {
    # Get device information using lsblk
    local dev_json
    dev_json=$(lsblk -Jo KNAME,FSTYPE,LABEL,MOUNTPOINT "${DEVICE}" 2>/dev/null | jq -r '.blockdevices[0]') || {
        echo "Error: Could not get device information for ${DEVICE}"
        return 1
    }

    # Check if already mounted
    local current_mount
    current_mount=$(jq -r '.mountpoint | select(type == "string")' <<< "$dev_json")
    if [[ -n "${current_mount}" ]] && [[ "${current_mount}" != "null" ]]; then
        echo "Device ${DEVICE} already mounted at ${current_mount}"
        return 0
    fi

    # Get filesystem info
    local ID_FS_LABEL ID_FS_TYPE
    ID_FS_LABEL=$(jq -r '.label | select(type == "string")' <<< "$dev_json")
    ID_FS_TYPE=$(jq -r '.fstype | select(type == "string")' <<< "$dev_json")

    # Determine mount options based on filesystem type
    local OPTS FSTYPE UDISKS2_ALLOW

    case "${ID_FS_TYPE}" in
        ext4)
            UDISKS2_ALLOW='errors=remount-ro'
            OPTS="${AUTOMOUNT_EXT4_MOUNT_OPTS:-rw,noatime,lazytime}"
            FSTYPE="ext4"
            ;;
        f2fs)
            UDISKS2_ALLOW='discard,nodiscard,compress_algorithm,compress_log_size,compress_extension,alloc_mode'
            OPTS="${AUTOMOUNT_F2FS_MOUNT_OPTS:-rw,noatime,lazytime,compress_algorithm=zstd,compress_chksum,atgc,gc_merge}"
            FSTYPE="f2fs"
            ensure_filesystem_registered "f2fs"
            ;;
        btrfs)
            UDISKS2_ALLOW='compress,compress-force,datacow,nodatacow,datasum,nodatasum,autodefrag,noautodefrag,degraded,device,discard,nodiscard,subvol,subvolid,space_cache'
            OPTS="${AUTOMOUNT_BTRFS_MOUNT_OPTS:-rw,noatime,lazytime,compress-force=zstd:4,space_cache=v2,discard=async}"
            FSTYPE="btrfs"

            # Check for main subvolume
            local mount_point_tmp="/var/run/automount-${DEVBASE}.tmp"
            mkdir -p "${mount_point_tmp}"
            if /bin/mount -t btrfs -o ro "${DEVICE}" "${mount_point_tmp}" 2>/dev/null; then
                local subvol="${AUTOMOUNT_BTRFS_MOUNT_SUBVOL:-@}"
                if [[ -d "${mount_point_tmp}/${subvol}" ]] && \
                    btrfs subvolume show "${mount_point_tmp}/${subvol}" &>/dev/null; then
                    OPTS+=",subvol=${subvol}"
                fi
                /bin/umount -l "${mount_point_tmp}"
                rmdir "${mount_point_tmp}"
            fi
            ;;
        vfat)
            UDISKS2_ALLOW='uid=$UID,gid=$GID,flush,utf8,shortname,umask,dmask,fmask,codepage,iocharset,usefree,showexec'
            OPTS="${AUTOMOUNT_FAT_MOUNT_OPTS:-rw,noatime,lazytime,uid=${DECK_UID},gid=${DECK_GID},utf8=1}"
            FSTYPE="vfat"
            ;;
        exfat)
            UDISKS2_ALLOW='uid=$UID,gid=$GID,dmask,errors,fmask,iocharset,namecase,umask'
            OPTS="${AUTOMOUNT_EXFAT_MOUNT_OPTS:-rw,noatime,lazytime,uid=${DECK_UID},gid=${DECK_GID}}"
            FSTYPE="exfat"
            ;;
        ntfs)
            UDISKS2_ALLOW='uid=$UID,gid=$GID,umask,dmask,fmask,locale,norecover,ignore_case,windows_names,compression,nocompression,big_writes,nls,nohidden,sys_immutable,sparse,showmeta,prealloc'
            OPTS="${AUTOMOUNT_NTFS_MOUNT_OPTS:-rw,noatime,lazytime,uid=${DECK_UID},gid=${DECK_GID},big_writes,umask=0022,ignore_case,windows_names}"
            FSTYPE="lowntfs-3g"
            ensure_filesystem_registered "lowntfs-3g"
            ;;
        *)
            echo "Error: Unsupported filesystem type: ${ID_FS_TYPE}"
            send_steam_url "system/devicemountresult" "${DEVBASE}/${MOUNT_ERROR}"
            return 2
            ;;
    esac

    # Filesystem check before mounting
    local ret=0
    if [[ "${ID_FS_TYPE}" == "ntfs" ]]; then
        ntfsfix "${DEVICE}" 2>/dev/null || ret=$?
    elif command -v "fsck.${ID_FS_TYPE}" &>/dev/null; then
        fsck."${ID_FS_TYPE}" -y "${DEVICE}" 2>/dev/null || ret=$?
    fi

    if (( ret != 0 && ret != 1 )); then
        send_steam_url "system/devicemountresult" "${DEVBASE}/${FSCK_ERROR}"
        echo "Error running fsck on ${DEVICE} (status = $ret)"
        exit 3
    fi

    local mount_point
    mount_point=$(with_global_lock "udisks2-mount-options" "${GLOBAL_LOCK_WAIT}" \
        mount_with_temporary_udisks_options "${FSTYPE}" "${UDISKS2_ALLOW}" "${OPTS}")

    if [[ -z "${mount_point}" ]] || [[ "${mount_point}" == "null" ]]; then
        echo "Error: Failed to mount ${DEVICE}"
        send_steam_url "system/devicemountresult" "${DEVBASE}/${MOUNT_ERROR}"
        return 4
    fi

    # Ensure the user can write to the mount point
    chmod 755 "${mount_point}" 2>/dev/null || true

    # Create a symlink in /run/media if label exists
    if [[ -n "${ID_FS_LABEL}" ]]; then
        local link_name="/run/media/${ID_FS_LABEL}"
        if [[ ! -e "${link_name}" ]]; then
            ln -sf "${mount_point}" "${link_name}"
        fi
    fi

    # Filesystem-specific post-mount operations
    if [[ "${ID_FS_TYPE}" == "btrfs" ]]; then
        # Create Steam subvolumes with compression disabled (workaround for Steam compression bug)
        for d in "${mount_point}"/steamapps/{downloading,temp}; do
            if ! btrfs subvolume show "$d" &>/dev/null; then
                mkdir -p "$d"
                rm -rf "$d"
                btrfs subvolume create "$d" 2>/dev/null || true
                chattr +C "$d" 2>/dev/null || true
                chown "${DECK_UID}:${DECK_GID}" "${d%/*}" "$d" 2>/dev/null || true
            fi
        done
    elif [[ "${AUTOMOUNT_COMPATDATA_BIND_MOUNT:-0}" == "1" ]] && \
         [[ "${ID_FS_TYPE}" == "vfat" || "${ID_FS_TYPE}" == "exfat" || "${ID_FS_TYPE}" == "ntfs" ]]; then
        # Bind mount compatdata folder from internal disk
        local DECK_HOME
        DECK_HOME="$(getent passwd ${DECK_UID} | cut -d: -f6)"

        if [[ -n "${DECK_HOME}" ]] && [[ -d "${DECK_HOME}" ]]; then
            mkdir -p "${mount_point}"/steamapps/compatdata
            chown "${DECK_UID}:${DECK_GID}" "${mount_point}"/steamapps{,/compatdata} 2>/dev/null || true
            mkdir -p "${DECK_HOME}"/.local/share/Steam/steamapps/compatdata
            chown "${DECK_UID}:${DECK_GID}" "${DECK_HOME}"/.local{,/share{,/Steam{,/steamapps{,/compatdata}}}} 2>/dev/null || true
            mount --rbind "${DECK_HOME}"/.local/share/Steam/steamapps/compatdata "${mount_point}"/steamapps/compatdata 2>/dev/null || true
        fi
    fi

    echo "Successfully mounted ${DEVICE} at ${mount_point}"
    send_steam_url "system/devicemountresult" "${DEVBASE}/${MOUNT_SUCCESS}"
}

# Unmount function
do_unmount() {
    # Get current mount point
    local dev_json mount_point
    dev_json=$(lsblk -Jo MOUNTPOINT "${DEVICE}" 2>/dev/null | jq -r '.blockdevices[0]') || {
        echo "Device ${DEVICE} not found"
        return 0
    }

    mount_point=$(jq -r '.mountpoint | select(type == "string")' <<< "$dev_json")

    if [[ -n "${mount_point}" ]] && [[ "${mount_point}" != "null" ]]; then
        # Remove symlinks to the mount point
        find /run/media -maxdepth 1 -xdev -type l -lname "${mount_point}" -exec rm -- {} \; 2>/dev/null || true

        # Unmount any bind mounts (like compatdata)
        if mountpoint -q "${mount_point}"/steamapps/compatdata 2>/dev/null; then
            /bin/umount -l -R "${mount_point}"/steamapps/compatdata 2>/dev/null || true
        fi

        echo "Unmounted ${DEVICE} from ${mount_point}"
    else
        # Remove all broken symlinks if we don't know the mount point
        find /run/media -maxdepth 1 -xdev -xtype l -exec rm -- {} \; 2>/dev/null || true
    fi
}

# Main logic
case "${ACTION}" in
    add)
        do_mount
        ;;
    remove)
        do_unmount
        ;;
    *)
        echo "Error: Unknown action '${ACTION}'"
        usage
        exit 1
        ;;
esac

exit 0
