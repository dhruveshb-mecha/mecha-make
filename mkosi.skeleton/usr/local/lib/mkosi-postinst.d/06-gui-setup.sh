#!/bin/bash
set -e

echo "Configuring GUI session..."

# Enable SDDM display manager for KDE Plasma
if systemctl list-unit-files | grep -q sddm.service; then
    # Force sddm as the default display manager
    echo "/usr/bin/sddm" > /etc/X11/default-display-manager
    
    # Reload presets to catch 99-mecha.preset
    systemctl preset sddm.service
    
    # Ensure graphical target is the default
    systemctl set-default graphical.target
fi
