#!/bin/bash
# Block device event handler - entry point for udev
# Calls the automount script to handle mount/unmount operations

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions
if [[ -f "${SCRIPT_DIR}/common-functions" ]]; then
    source "${SCRIPT_DIR}/common-functions"
fi

# Validate arguments
if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <add|remove> <device>"
    exit 1
fi

ACTION="$1"
DEVICE="$2"

# Call the automount script
exec "${SCRIPT_DIR}/automount.sh" "${ACTION}" "${DEVICE}"
