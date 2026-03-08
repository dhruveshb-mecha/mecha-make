#!/bin/bash
set -e

echo "Configuring locales..."

# Ensure standard locales are generated for proper tool behavior and error messages
if [ -f /etc/locale.gen ]; then
    sed -i 's/^# *\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen
    locale-gen || true
fi

# Set default locale for the system
echo "LANG=en_US.UTF-8" > /etc/default/locale
