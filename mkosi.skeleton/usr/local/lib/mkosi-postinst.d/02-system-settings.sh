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

# Enable SSH server at boot and configure it
echo "Enabling SSH..."
systemctl enable ssh.service || systemctl enable sshd.service || true

# Allow password authentication and root login over SSH
mkdir -p /etc/ssh/sshd_config.d
cat > /etc/ssh/sshd_config.d/10-mecha.conf <<EOF
PasswordAuthentication yes
PermitRootLogin yes
EOF
chmod 644 /etc/ssh/sshd_config.d/10-mecha.conf
