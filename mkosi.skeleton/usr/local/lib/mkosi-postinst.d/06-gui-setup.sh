#!/bin/bash
set -e

echo "Configuring GUI session..."

# Enable SDDM display manager for KDE Plasma
if [ -f /usr/lib/systemd/system/sddm.service ]; then
    # Unmask units that often cause 'preset-all' failures in Kali/KDE
    # Direct removal is more reliable in a chroot than 'systemctl unmask'
    for unit in \
        /etc/systemd/system/sudo.service \
        /etc/systemd/system/cryptdisks-early.service \
        /etc/systemd/system/screen-cleanup.service \
        /etc/systemd/system/cryptdisks.service \
        /etc/systemd/system/hwclock.service \
        /etc/systemd/system/x11-common.service \
        /etc/systemd/system/display-manager.service \
        /etc/systemd/user/app-org.kde.plasma-welcome@autostart.service \
        /etc/systemd/user/app-org.kde.discover.notifier@autostart.service \
        /etc/systemd/user/app-org.kde.kdeconnect.daemon@autostart.service
    do
        [ -L "$unit" ] && [ "$(readlink "$unit")" = "/dev/null" ] && rm -f "$unit"
    done

    # Force sddm as the default display manager
    mkdir -p /etc/X11
    echo "/usr/bin/sddm" > /etc/X11/default-display-manager || true

    # Enable sddm service manually if symlink missing (preset handles it, this is a guard)
    if [ ! -L /etc/systemd/system/display-manager.service ]; then
        ln -sf /usr/lib/systemd/system/sddm.service /etc/systemd/system/display-manager.service || true
    fi

    # Ensure graphical target is the default
    systemctl set-default graphical.target || true
fi
