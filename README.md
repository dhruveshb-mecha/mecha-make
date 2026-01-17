# Mechanix OS Build System

Build system for creating custom Linux distributions and bootloaders for Mecha Comet devices.

## Overview
This repository contains mkosi configuration and assets to build a reproducible Fedora-based image for the "mecha" project.

## Prerequisites
- Ubuntu/Debian (or other Linux host)
- mkosi
- qemu (for cross-arch or image testing)
- debootstrap (if building Debian/Ubuntu images)

Install common dependencies:
```sh
sudo apt update
sudo apt install -y mkosi qemu-system-x86 debootstrap
```

## Summary for mkosi Configuration
to get info of current mkosi configuration:
```sh
mkosi summary
```

## Build
Build the image using mkosi with the provided configuration:
```sh
sudo mkosi -f build
```

## To validate the rootfs
You can login into the built image to validate its contents:
```sh
sudo mkosi shell
```