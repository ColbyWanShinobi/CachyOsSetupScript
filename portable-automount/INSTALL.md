# Installation Guide

## Quick Start

### Installation

```bash
cd portable-automount
sudo ./install.sh
```

### Uninstallation

```bash
cd portable-automount
sudo ./uninstall.sh
```

## Prerequisites

### Required Packages

Before installing, ensure you have these packages:

#### Debian/Ubuntu
```bash
sudo apt-get install systemd udev jq util-linux
```

#### Fedora/RHEL/CentOS
```bash
sudo dnf install systemd udev jq util-linux-core
```

#### Arch Linux
```bash
sudo pacman -S systemd jq util-linux
```

### Filesystem Support Packages

Install the packages for the filesystems you want to support:

#### Debian/Ubuntu
```bash
# btrfs support
sudo apt-get install btrfs-progs

# f2fs support
sudo apt-get install f2fs-tools

# ext4 support (usually pre-installed)
sudo apt-get install e2fsprogs

# FAT32 support
sudo apt-get install dosfstools

# exFAT support
sudo apt-get install exfatprogs

# NTFS support
sudo apt-get install ntfs-3g
```

#### Fedora/RHEL/CentOS
```bash
# btrfs support
sudo dnf install btrfs-progs

# f2fs support
sudo dnf install f2fs-tools

# ext4 support (usually pre-installed)
sudo dnf install e2fsprogs

# FAT32 support
sudo dnf install dosfstools

# exFAT support
sudo dnf install exfatprogs

# NTFS support
sudo dnf install ntfs-3g
```

#### Arch Linux
```bash
# btrfs support
sudo pacman -S btrfs-progs

# f2fs support
sudo pacman -S f2fs-tools

# ext4 support (usually pre-installed)
sudo pacman -S e2fsprogs

# FAT32 support
sudo pacman -S dosfstools

# exFAT support
sudo pacman -S exfatprogs

# NTFS support
sudo pacman -S ntfs-3g
```

## Installation Steps

1. **Download or clone the portable-automount directory**

2. **Navigate to the directory**
   ```bash
   cd portable-automount
   ```

3. **Run the installation script**
   ```bash
   sudo ./install.sh
   ```

4. **Verify installation**
   The script will:
   - Install scripts to `/usr/local/libexec/automount/`
   - Install udev rules to `/etc/udev/rules.d/`
   - Install configuration to `/etc/default/automount-config`
   - Reload udev rules

5. **Test the installation**
   - Insert an SD card or USB drive
   - Check if it's mounted automatically:
     ```bash
     lsblk
     ```
   - Look for mounts under `/run/media/`
   - If several drives appear at once, mounts now run in parallel per device. A slow `fsck` on one disk should not block the others.

## Configuration

After installation, you can customize the behavior by editing:

```bash
sudo nano /etc/default/automount-config
```

### Common Customizations

#### Change UID/GID for FAT/exFAT/NTFS mounts
```bash
AUTOMOUNT_UID="1000"
AUTOMOUNT_GID="1000"
```

#### Enable Steam compatdata bind mount
```bash
AUTOMOUNT_COMPATDATA_BIND_MOUNT="1"
```

#### Customize btrfs mount options
```bash
AUTOMOUNT_BTRFS_MOUNT_OPTS="rw,noatime,lazytime,compress-force=zstd:4,space_cache=v2,discard=async"
```

#### Customize NTFS mount options
```bash
AUTOMOUNT_NTFS_MOUNT_OPTS="rw,noatime,lazytime,uid=1000,gid=1000,big_writes,umask=0022,ignore_case,windows_names"
```

#### Adjust lock wait times
```bash
# Per-device lock for duplicate events on the same block device
AUTOMOUNT_DEVICE_LOCK_WAIT="20"

# Short shared locks for /etc/filesystems and /etc/udisks2/mount_options.conf
AUTOMOUNT_GLOBAL_LOCK_WAIT="60"
```

Use a larger `AUTOMOUNT_DEVICE_LOCK_WAIT` only if the same device frequently emits overlapping `add` events. Increasing `AUTOMOUNT_GLOBAL_LOCK_WAIT` is usually unnecessary unless the machine is under heavy storage contention.

### Customizing Udev Rules

To change which devices are auto-mounted, edit the udev rules:

```bash
sudo nano /etc/udev/rules.d/99-automount.rules
```

For example, to also mount USB drives (sd* devices), change:
```bash
KERNEL!="mmcblk*",              GOTO="automount_end"
```
to:
```bash
KERNEL!="mmcblk*|sd*",          GOTO="automount_end"
```

After changing udev rules, reload them:
```bash
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=block
```

## Troubleshooting

### Devices not mounting automatically

1. **Check udev is receiving events**
   ```bash
   sudo udevadm monitor
   ```
   Insert a device and watch for events

2. **Check the udev rules are loaded**
   ```bash
   udevadm control --reload-rules
   ```

3. **Check system logs**
   ```bash
   journalctl -f
   ```
   Insert a device and watch for errors

4. **Verify udisks2 is running**
   ```bash
   systemctl status udisks2
   ```

### Slow or failing disk blocks other mounts

Current versions use per-device locks, so one unhealthy disk should no longer serialize every other mount job. If mounts still appear delayed:

1. **Check for device-specific lock timeouts**
   ```bash
   journalctl -b | grep "Timed out waiting for device lock"
   ```
   This means the same device generated overlapping events and exhausted `AUTOMOUNT_DEVICE_LOCK_WAIT`.

2. **Check for shared-resource lock timeouts**
   ```bash
   journalctl -b | grep "Timed out waiting for global lock"
   ```
   This points to contention around `/etc/filesystems` or `/etc/udisks2/mount_options.conf`, which should be brief.

3. **Check for slow filesystem checks**
   ```bash
   journalctl -b | grep -E "fsck|ntfsfix|mount_error"
   ```
   If one disk is taking a long time in `fsck`, that device can still be slow to mount, but other devices should continue independently.

4. **Test one device manually**
   ```bash
   sudo /usr/local/libexec/automount/automount.sh add sda1
   ```
   Replace `sda1` with the actual device. This helps isolate whether the delay is caused by that disk's health, filesystem checks, or mount options.

### Permission denied errors

Ensure your user is in the correct groups:
```bash
sudo usermod -aG disk,storage $USER
```

Log out and back in for group changes to take effect.

### Filesystem not supported

Install the appropriate filesystem tools (see Prerequisites section).

### Scripts not executing

Check that scripts are executable:
```bash
ls -l /usr/local/libexec/automount/
```

If not, make them executable:
```bash
sudo chmod +x /usr/local/libexec/automount/*.sh
```

## Uninstallation

To remove the auto-mount system:

```bash
cd portable-automount
sudo ./uninstall.sh
```

This will:
- Remove all installed scripts
- Remove udev rules
- Ask if you want to remove the configuration file
- Reload udev rules

Note: Currently mounted devices will remain mounted. You can manually unmount them using your file manager or the `umount` command.

## Advanced Usage

### Testing without installing

You can test the mount script manually:

```bash
# Find your device name (e.g., sda1, mmcblk0p1)
lsblk

# Test the mount script
sudo /path/to/portable-automount/scripts/automount.sh add sda1
```

### Viewing mount options

Check what options were used to mount a device:
```bash
mount | grep /run/media/
```

### Manual unmount

To manually unmount a device:
```bash
sudo umount /run/media/LABEL_NAME
```

Or use the file manager's eject function.
