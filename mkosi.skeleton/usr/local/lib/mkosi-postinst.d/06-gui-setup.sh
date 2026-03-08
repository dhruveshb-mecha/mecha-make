#!/bin/bash
set -e

echo "Configuring GUI session..."

# Enable SDDM display manager for KDE Plasma
if [ -f /lib/systemd/system/sddm.service ] || [ -f /usr/lib/systemd/system/sddm.service ]; then
    # Force sddm as the default display manager
    echo "/usr/bin/sddm" > /etc/X11/default-display-manager
    
    # Unmask units that often cause 'preset-all' failures in Kali/KDE
    systemctl unmask org.kde.plasma-welcome.service || true
    systemctl --user --global unmask app-org.kde.plasma-welcome@autostart.service || true
    systemctl --user --global unmask app-org.kde.discover.notifier@autostart.service || true
    systemctl --user --global unmask app-org.kde.kdeconnect.daemon@autostart.service || true
    systemctl unmask sudo.service || true
    systemctl unmask cryptdisks-early.service || true
    systemctl unmask screen-cleanup.service || true
    systemctl unmask cryptdisks.service || true
    systemctl unmask hwclock.service || true
    systemctl unmask x11-common.service || true

    # Enable sddm service
    systemctl enable sddm.service || true
    
    # Reload presets as a fallback
    systemctl preset sddm.service || true
    
    # Ensure graphical target is the default
    systemctl set-default graphical.target || true
fi
