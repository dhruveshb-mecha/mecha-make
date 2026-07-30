#!/bin/bash
# Builds (if needed) and boots the mechanix-os-qemu image in QEMU.
#
# mkosi's own `mkosi vm` doesn't work for this profile: the Fedora
# tools-tree qemu segfaults inside mkosi's own sandbox under Console=gui
# (upstream mkosi issue https://github.com/systemd/mkosi/issues/3941), so
# this runs the host's own qemu-system-x86_64 directly against the built
# disk image instead. See README.md "Testing in QEMU" for the background on
# every flag below.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

IMAGE=mechanix-os-qemu.raw
OVMF_CODE=/usr/share/OVMF/OVMF_CODE_4M.fd
OVMF_VARS_TEMPLATE=/usr/share/OVMF/OVMF_VARS_4M.fd
OVMF_VARS=/tmp/mechanix-os-qemu-ovmf-vars.fd

if [[ ! -f "$OVMF_CODE" || ! -f "$OVMF_VARS_TEMPLATE" ]]; then
    echo "OVMF firmware not found at $OVMF_CODE / $OVMF_VARS_TEMPLATE - install it with: sudo apt install ovmf" >&2
    exit 1
fi

if [[ "${1:-}" == "--build" || ! -f "$IMAGE" ]]; then
    echo "Building $IMAGE..."
    sudo mkosi clean --profile=qemu -f
    sudo mkosi build --profile=qemu -f
fi

# Fresh EFI vars every run so leftover boot-order/state from a previous
# image never carries over.
cp "$OVMF_VARS_TEMPLATE" "$OVMF_VARS"

sudo qemu-system-x86_64 \
    -enable-kvm \
    -machine q35 \
    -cpu host \
    -smp 4 \
    -m 4096 \
    -drive if=pflash,format=raw,readonly=on,file="$OVMF_CODE" \
    -drive if=pflash,format=raw,file="$OVMF_VARS" \
    -drive file="$IMAGE",if=none,id=bootdisk,format=raw \
    -device virtio-blk-pci,drive=bootdisk,bootindex=1 \
    -display gtk,gl=on,zoom-to-fit=on \
    -device virtio-vga-gl,xres=1080,yres=1240 \
    -device qemu-xhci,id=xhci \
    -device usb-tablet,bus=xhci.0 \
    -device usb-kbd,bus=xhci.0
