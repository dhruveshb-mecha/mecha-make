#!/bin/bash
set -e

echo "Configuring GUI session..."

# Enable SDDM display manager for KDE Plasma
if [ -f /lib/systemd/system/sddm.service ] || [ -f /usr/lib/systemd/system/sddm.service ]; then
    # Force sddm as the default display manager
    echo "/usr/bin/sddm" > /etc/X11/default-display-manager
    
    # Enable sddm service
    systemctl enable sddm.service
    
    # Reload presets as a fallback
    systemctl preset sddm.service
    
    # Ensure graphical target is the default
    systemctl set-default graphical.target
fi
