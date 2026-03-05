#!/bin/bash
set -e

echo "Applying system settings..."

# Configure systemd-logind to ignore power key
mkdir -p /etc/systemd
cat > /etc/systemd/logind.conf <<EOF
[Login]
HandlePowerKey=ignore
EOF
chmod 644 /etc/systemd/logind.conf
