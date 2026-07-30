#!/bin/bash
# Boots a prebuilt mechanix-os-qemu.raw image in QEMU. Companion script for
# the qemu-image-release.yml GitHub release assets - unlike run-qemu.sh in
# the main repo, this never tries to build the image (there's no mkosi
# checkout alongside a downloaded release asset), it just boots whatever
# mechanix-os-qemu.raw sits next to it.
#
# Requires qemu-system-x86, qemu-system-gui, and ovmf installed:
#   sudo apt install -y qemu-system-x86 qemu-system-gui ovmf
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

IMAGE=mechanix-os-qemu.raw
OVMF_CODE=/usr/share/OVMF/OVMF_CODE_4M.fd
OVMF_VARS_TEMPLATE=/usr/share/OVMF/OVMF_VARS_4M.fd
OVMF_VARS=/tmp/mechanix-os-qemu-ovmf-vars.fd

if [[ ! -f "$IMAGE" ]]; then
    echo "$IMAGE not found next to this script - download it from the release and decompress it here first." >&2
    exit 1
fi

if [[ ! -f "$OVMF_CODE" || ! -f "$OVMF_VARS_TEMPLATE" ]]; then
    echo "OVMF firmware not found at $OVMF_CODE / $OVMF_VARS_TEMPLATE - install it with: sudo apt install ovmf" >&2
    exit 1
fi

# Fresh EFI vars every run so leftover boot-order/state from a previous run
# never carries over.
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
