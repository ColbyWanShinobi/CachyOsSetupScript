#!/bin/bash

set -euo pipefail

SCRIPTLINK=$(readlink -f "$0")
SCRIPTDIR=$(dirname "${SCRIPTLINK}")

SOURCE_CONF="${SCRIPTDIR}/etc/modprobe.d/it87.conf"
TARGET_CONF="/etc/modprobe.d/it87.conf"
MODULE_NAME="it87"

if [[ ! -f "${SOURCE_CONF}" ]]; then
    echo "Error: missing source config: ${SOURCE_CONF}" >&2
    exit 1
fi

echo "Installing ${SOURCE_CONF} to ${TARGET_CONF}..."
sudo install -Dm644 "${SOURCE_CONF}" "${TARGET_CONF}"

if lsmod | grep -q "^${MODULE_NAME}\\b"; then
    echo "Reloading ${MODULE_NAME} to apply the new modprobe option..."

    if sudo modprobe -r "${MODULE_NAME}"; then
        sudo modprobe "${MODULE_NAME}"
        echo "Reloaded ${MODULE_NAME} successfully."
    else
        echo "Warning: could not unload ${MODULE_NAME}. It may still be in use." >&2
        echo "The new option is installed and will apply on the next successful reload or reboot." >&2
        exit 0
    fi
else
    echo "${MODULE_NAME} is not currently loaded."
    echo "Loading ${MODULE_NAME} now so the new option takes effect immediately..."
    sudo modprobe "${MODULE_NAME}"
fi

echo "Done."
