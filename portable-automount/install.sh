#!/bin/bash
# Installation script for portable auto-mount system

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

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_info "Installing portable auto-mount system..."

# Check for required commands
REQUIRED_COMMANDS=(systemd-run udevadm jq lsblk busctl)
MISSING_COMMANDS=()

for cmd in "${REQUIRED_COMMANDS[@]}"; do
    if ! command -v "$cmd" &>/dev/null; then
        MISSING_COMMANDS+=("$cmd")
    fi
done

if [[ ${#MISSING_COMMANDS[@]} -gt 0 ]]; then
    print_error "Missing required commands: ${MISSING_COMMANDS[*]}"
    print_info "Please install the following packages:"
    print_info "  - systemd (for systemd-run)"
    print_info "  - udev (for udevadm)"
    print_info "  - jq (for JSON parsing)"
    print_info "  - util-linux (for lsblk)"
    exit 1
fi

# Create installation directories
print_info "Creating installation directories..."
mkdir -p /usr/local/libexec/automount
mkdir -p /etc/udev/rules.d
mkdir -p /etc/default

# Install scripts
print_info "Installing scripts to /usr/local/libexec/automount/..."
install -m 755 "${SCRIPT_DIR}/scripts/block-device-event.sh" /usr/local/libexec/automount/
install -m 755 "${SCRIPT_DIR}/scripts/automount.sh" /usr/local/libexec/automount/
install -m 644 "${SCRIPT_DIR}/scripts/common-functions" /usr/local/libexec/automount/

# Install udev rules
print_info "Installing udev rules to /etc/udev/rules.d/..."
install -m 644 "${SCRIPT_DIR}/udev/99-automount.rules" /etc/udev/rules.d/
install -m 644 "${SCRIPT_DIR}/udev/99-automount-labeled.rules" /etc/udev/rules.d/

# Install configuration file (don't overwrite if exists)
if [[ -f /etc/default/automount-config ]]; then
    print_warn "Configuration file /etc/default/automount-config already exists"
    print_warn "Backing up to /etc/default/automount-config.bak"
    cp /etc/default/automount-config /etc/default/automount-config.bak
    install -m 644 "${SCRIPT_DIR}/config/automount-config" /etc/default/automount-config.new
    print_info "New configuration saved as /etc/default/automount-config.new"
    print_info "Please review and merge changes manually if needed"
else
    print_info "Installing configuration to /etc/default/automount-config..."
    install -m 644 "${SCRIPT_DIR}/config/automount-config" /etc/default/automount-config
fi

# Reload udev rules
print_info "Reloading udev rules..."
udevadm control --reload-rules

# Trigger automount for existing devices
print_info "Triggering automount for existing devices..."
udevadm trigger --action=add --subsystem-match=block

print_info ""
print_info "=========================================="
print_info "Installation completed successfully!"
print_info "=========================================="
print_info ""
print_info "Configuration file: /etc/default/automount-config"
print_info "Scripts location: /usr/local/libexec/automount/"
print_info "Udev rules: /etc/udev/rules.d/99-automount*.rules"
print_info ""
print_info "The system will now automatically mount:"
print_info "  - All SD cards (mmcblk* devices)"
print_info "  - All labeled USB/SATA/NVMe drives (sd*/nvme* devices, excluding EFI/VTOYEFI)"
print_info ""
print_info "To customize behavior, edit: /etc/default/automount-config"
print_info "To uninstall, run: sudo ./uninstall.sh"
print_info ""

# Check for optional filesystem tools
print_info "Checking for optional filesystem tools..."
OPTIONAL_TOOLS=(
    "mkfs.btrfs:btrfs-progs"
    "mkfs.f2fs:f2fs-tools"
    "mkfs.ext4:e2fsprogs"
    "mkfs.vfat:dosfstools"
    "mkfs.exfat:exfatprogs or exfat-utils"
    "mkfs.ntfs:ntfs-3g"
    "ntfsfix:ntfs-3g"
)

MISSING_TOOLS=()
for tool_info in "${OPTIONAL_TOOLS[@]}"; do
    tool="${tool_info%%:*}"
    package="${tool_info#*:}"
    if ! command -v "$tool" &>/dev/null; then
        MISSING_TOOLS+=("  - $tool (from $package)")
    fi
done

if [[ ${#MISSING_TOOLS[@]} -gt 0 ]]; then
    print_warn "Some optional filesystem tools are not installed:"
    for tool in "${MISSING_TOOLS[@]}"; do
        echo "$tool"
    done
    print_info "Install these packages to enable support for all filesystems"
fi

print_info ""
print_info "Installation complete!"
