#!/bin/bash
set -e

echo "Configuring networking..."

# Fix sudo hostname resolution error
if ! grep -q "127.0.1.1 comet" /etc/hosts; then
    echo "127.0.1.1 comet" >> /etc/hosts
fi

# Create a default network configuration for all interfaces
mkdir -p /etc/systemd/network
cat > /etc/systemd/network/80-default.network <<EOF
[Match]
Name=en* eth*

[Network]
DHCP=yes
EOF

# Configure systemd-resolved with fallback DNS
mkdir -p /etc/systemd/resolved.conf.d
cat > /etc/systemd/resolved.conf.d/fallback.conf <<EOF
[Resolve]
FallbackDNS=8.8.8.8 8.8.4.4
EOF

# Enable systemd-resolved and set up the resolv.conf symlink
systemctl enable systemd-resolved
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

# Fix ping permissions for non-root users
if [ -f /usr/bin/ping ]; then
    chmod +s /usr/bin/ping
fi
