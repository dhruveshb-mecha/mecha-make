#!/bin/bash
set -e

echo "Configuring time and timezone..."

# Enable systemd-timesyncd for network time synchronization
# This is usually handled by presets, but we ensure it's enabled here as well
if command -v systemctl > /dev/null; then
    systemctl enable systemd-timesyncd.service || true
fi

# Note: Timezone will be automatically adjusted by Plasma/KDE if geoclue2 and 
# appropriate KDE services are running and have internet access.
# For a base default, we can ensure /etc/localtime is manageable.

# Ensure the hardware clock is set to UTC
if [ -f /etc/adjtime ]; then
    sed -i 's/LOCAL/UTC/' /etc/adjtime || true
else
    echo "0.0 0 0.0" > /etc/adjtime
    echo "0" >> /etc/adjtime
    echo "UTC" >> /etc/adjtime
fi

echo "Time synchronization configured."
