#!/bin/bash

GRUB_FILE="/etc/default/grub"

# Create the file if it doesn't exist
if [ ! -f "$GRUB_FILE" ]; then
    touch "$GRUB_FILE"
fi

# Function to add or update a key-value pair
add_or_update_key_value() {
    local key="$1"
    local value="$2"
    if grep -q "^$key=" "$GRUB_FILE"; then
        sed -i "s/^$key=.*/#$key=/" "$GRUB_FILE"
    fi
    echo "$key=$value" >> "$GRUB_FILE"
}

# Add or update the required key-value pairs
add_or_update_key_value "GRUB_TIMEOUT" "5"
#add_or_update_key_value "GRUB_DISTRIBUTOR" "\"\$(sed 's, release .*\$,,' /etc/system-release)\""
add_or_update_key_value "GRUB_DEFAULT" "saved"
add_or_update_key_value "GRUB_SAVEDEFAULT" "true"
add_or_update_key_value "GRUB_DISABLE_OS_PROBER" "false"
