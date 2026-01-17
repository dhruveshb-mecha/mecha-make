#!/bin/bash
set -e

USERNAME=mecha
PASSWORD="mecha"

# Create user with home directory and bash shell
useradd -m -s /bin/bash "$USERNAME"

# Set the user password
echo "$USERNAME:$PASSWORD" | chpasswd

# Add the user to the 'wheel' group for sudo privileges
usermod -aG wheel "$USERNAME"

# Optional: allow wheel group to use sudo without password
# Uncomment if you want passwordless sudo
# echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
