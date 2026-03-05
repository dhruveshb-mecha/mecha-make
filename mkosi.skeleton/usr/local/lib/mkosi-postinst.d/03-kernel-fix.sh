#!/bin/bash
set -e

echo "Applying kernel and DTB fixes..."

# mkosi 26 expects DTBs in /usr/lib/modules/KVER/dtb/
KVER="6.12.20+mecha+"
mkdir -p "/usr/lib/modules/$KVER"

# Move the directory from the Kali package location to the standard location
if [ -d "/usr/lib/linux-image-$KVER" ] && [ ! -d "/usr/lib/modules/$KVER/dtb" ]; then
    mv "/usr/lib/linux-image-$KVER" "/usr/lib/modules/$KVER/dtb"
fi
