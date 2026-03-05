#!/bin/bash
set -e

# --- 1. User Configuration ---
USERNAME=mecha
PASSWORD="mecha"

echo "Configuring user: $USERNAME"

# Create user if it doesn't exist
if ! id "$USERNAME" &>/dev/null; then
    useradd -m -s /bin/bash "$USERNAME"
    echo "$USERNAME:$PASSWORD" | chpasswd
    usermod -aG sudo,video,render,input,audio,netdev,plugdev "$USERNAME"
else
    # Ensure existing user has correct groups
    usermod -aG sudo,video,render,input,audio,netdev,plugdev "$USERNAME"
fi

# Ensure home directory permissions
chown -R "$USERNAME:$USERNAME" "/home/$USERNAME"
