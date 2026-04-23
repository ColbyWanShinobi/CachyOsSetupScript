# Portable Auto-Mount System

A portable automatic disk mounting system for Linux, extracted from the Bazzite project. This system automatically mounts removable storage devices (SD cards, USB drives, external drives) with optimized filesystem-specific options.

## Features

- Automatic mounting of removable storage devices (SD cards, USB drives, etc.)
- Support for multiple filesystems: btrfs, f2fs, ext4, FAT32, exFAT, NTFS
- Filesystem-specific mount options for optimal performance
- Optional Steam-specific optimizations (btrfs subvolumes for downloading/temp, compatdata bind mounts)
- Label-based filtering (e.g., auto-mount drives labeled "steamgames")
- Safe concurrent mounting with file locking
- Automatic filesystem checking and repair

## Requirements

### Required Packages
- `systemd` - For systemd-run and udev
- `udev` - Device management
- `jq` - JSON parsing
- `udisks2` - Disk mounting via DBus
- `coreutils` - Basic utilities (mkdir, chown, etc.)

### Filesystem-Specific Tools
- `btrfs-progs` - For btrfs support
- `f2fs-tools` - For f2fs support
- `e2fsprogs` - For ext4 support (usually pre-installed)
- `dosfstools` - For FAT32 support
- `exfatprogs` or `exfat-utils` - For exFAT support
- `ntfs-3g` - For NTFS support

## Installation

Run the install script as root:

```bash
sudo ./install.sh
```

This will:
1. Copy udev rules to `/etc/udev/rules.d/`
2. Install scripts to `/usr/local/libexec/automount/`
3. Copy configuration to `/etc/default/automount-config`
4. Reload udev rules and trigger automount for existing devices

## Uninstallation

Run the uninstall script as root:

```bash
sudo ./uninstall.sh
```

This will remove all installed files and reload udev rules.

## Configuration

Edit `/etc/default/automount-config` to customize:

- Mount options for each filesystem type
- Enable/disable Steam-specific features
- Subvolume names for btrfs
- Format options for each filesystem

Example configuration options:
```bash
# Mount options for btrfs
AUTOMOUNT_BTRFS_MOUNT_OPTS="rw,noatime,lazytime,compress-force=zstd:4,space_cache=v2,discard=async"

# Enable Steam compatdata bind mount for FAT/exFAT/NTFS (0=disabled, 1=enabled)
AUTOMOUNT_COMPATDATA_BIND_MOUNT="0"
```

## How It Works

1. When a storage device is connected, udev detects it and triggers the automount system
2. The system uses `systemd-run` to execute the mount script asynchronously
3. Device information is retrieved via `lsblk` and `jq`
4. Filesystem-specific mount options are applied from the configuration file
5. The device is mounted via udisks2 DBus interface
6. For btrfs: Special subvolumes are created for Steam directories if needed
7. For FAT/exFAT/NTFS: Optional bind mounts for Steam compatdata

## Udev Rules

### 99-automount.rules
Automatically mounts all mmcblk* (SD cards) devices with filesystems.

### 99-automount-labeled.rules
Automatically mounts all labeled sd* (USB/SATA) and nvme* (NVMe) devices with filesystems, excluding partitions labeled "EFI" or "VTOYEFI".

You can customize these rules to match your specific needs (device types, labels, etc.).

## Security Considerations

- Devices are mounted with user-specific UID/GID (1000:1000 by default for FAT/exFAT/NTFS)
- Only devices with valid filesystems are mounted
- Filesystem checking (fsck) is performed before mounting
- Mount points are created in `/run/media/` with appropriate permissions

## Troubleshooting

### Devices not auto-mounting

1. Check udev rules are loaded:
   ```bash
   sudo udevadm control --reload-rules
   ```

2. Monitor udev events:
   ```bash
   sudo udevadm monitor
   ```

3. Check system logs:
   ```bash
   journalctl -f
   ```

### Permission issues

Ensure your user is in the appropriate groups:
```bash
sudo usermod -aG disk,storage $USER
```

## Original Source

This system is based on the jupiter-hw-support package from:
- Bazzite: https://github.com/ublue-os/bazzite
- SteamOS: https://gitlab.com/evlaV/jupiter-hw-support

## License

GPLv3 - See LICENSE file for details
