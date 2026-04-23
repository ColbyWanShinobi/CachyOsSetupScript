#!/bin/bash
# Uninstallation script for portable auto-mount system

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    print_error "This script must be run as root (use sudo)"
    exit 1
fi

print_info "Uninstalling portable auto-mount system..."

# Remove scripts
if [[ -d /usr/local/libexec/automount ]]; then
    print_info "Removing scripts from /usr/local/libexec/automount/..."
    rm -rf /usr/local/libexec/automount
else
    print_warn "Scripts directory not found: /usr/local/libexec/automount/"
fi

# Remove udev rules
print_info "Removing udev rules..."
rm -f /etc/udev/rules.d/99-automount.rules
rm -f /etc/udev/rules.d/99-automount-labeled.rules

# Ask about configuration file
if [[ -f /etc/default/automount-config ]]; then
    read -p "Remove configuration file /etc/default/automount-config? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Removing configuration file..."
        rm -f /etc/default/automount-config
        rm -f /etc/default/automount-config.bak
        rm -f /etc/default/automount-config.new
    else
        print_info "Keeping configuration file"
    fi
fi

# Restore original udisks2 config if backup exists
if [[ -f /etc/udisks2/mount_options.conf.orig ]]; then
    print_info "Restoring original udisks2 mount options..."
    mv -f /etc/udisks2/mount_options.conf.orig /etc/udisks2/mount_options.conf
fi

# Remove temporary udisks2 config if it exists
if [[ -f /etc/udisks2/mount_options.conf ]]; then
    # Check if it's our config (contains automount-specific content)
    if grep -q "lowntfs-3g_allow\|f2fs_allow" /etc/udisks2/mount_options.conf 2>/dev/null; then
        print_info "Removing automount-specific udisks2 configuration..."
        rm -f /etc/udisks2/mount_options.conf
    fi
fi

# Reload udev rules
print_info "Reloading udev rules..."
if command -v udevadm &>/dev/null; then
    udevadm control --reload-rules
    udevadm trigger --subsystem-match=block
fi

print_info ""
print_info "=========================================="
print_info "Uninstallation completed successfully!"
print_info "=========================================="
print_info ""
print_info "Note: Any currently mounted devices will remain mounted"
print_info "You can manually unmount them using 'umount' or the file manager"
print_info ""
