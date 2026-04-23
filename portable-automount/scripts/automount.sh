#!/bin/bash
# Automatic disk mounting script with multi-filesystem support
# Based on SteamOS automount with btrfs enhancements

set -euo pipefail

# File locking to prevent concurrent mount operations
if [[ "${FLOCKER:-}" != "$0" ]]; then
    exec env FLOCKER="$0" flock -e -w 20 "$0" "$0" "$@"
fi

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
            # Ensure f2fs is in /etc/filesystems
            if [[ ! -f /etc/filesystems ]] || ! grep -q '\bf2fs\b' /etc/filesystems; then
                echo "f2fs" >> /etc/filesystems
            fi
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
            # Ensure lowntfs-3g is in /etc/filesystems
            if [[ ! -f /etc/filesystems ]] || ! grep -q '\blowntfs-3g\b' /etc/filesystems; then
                echo "lowntfs-3g" >> /etc/filesystems
            fi
            ;;
        *)
            echo "Error: Unsupported filesystem type: ${ID_FS_TYPE}"
            send_steam_url "system/devicemountresult" "${DEVBASE}/${MOUNT_ERROR}"
            return 2
            ;;
    esac

    # Configure udisks2 mount options
    udisks2_mount_options_conf='/etc/udisks2/mount_options.conf'
    mkdir -p "$(dirname "${udisks2_mount_options_conf}")"

    # Backup original config if exists
    if [[ -f "${udisks2_mount_options_conf}" ]] && [[ ! -f "${udisks2_mount_options_conf}.orig" ]]; then
        mv -f "${udisks2_mount_options_conf}"{,.orig}
    fi

    # Write temporary mount options
    echo -e "[defaults]\n${FSTYPE}_allow=${UDISKS2_ALLOW},${OPTS}" > "${udisks2_mount_options_conf}"

    # Cleanup function to restore original config
    trap 'rm -f "${udisks2_mount_options_conf}"; [[ -f "${udisks2_mount_options_conf}.orig" ]] && mv -f "${udisks2_mount_options_conf}"{.orig,}' EXIT

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

    # Mount via udisks2 DBus
    local mount_point
    mount_point=$(make_dbus_udisks_call call 'data[0]' s \
                                 "block_devices/${DEVBASE}" \
                                 Filesystem Mount \
                                 'a{sv}' 4 \
                                 as-user s "$(getent passwd ${DECK_UID} | cut -d: -f1)" \
                                 auth.no_user_interaction b true \
                                 fstype s "$FSTYPE" \
                                 options s "$OPTS")

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
