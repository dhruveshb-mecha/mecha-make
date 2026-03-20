# Mechanix OS Build System

Build system for creating custom Linux distributions and bootloaders for Mecha Comet devices.

## Overview
This repository contains mkosi configuration and assets to build a reproducible Fedora-based image for the "mecha" project.

## Project Layout
- `mkosi.conf`: shared Fedora 43 `arm64` base image settings and common packages
- `mkosi.conf.d/`: desktop-specific drop-ins; Plasma Mobile remains the default build path
- `mkosi.profiles/xfce/`: optional XFCE profile for the low-power target, including its own `greetd` session override
- `mkosi.skeleton/`: files copied into the image before package installation, including presets, repos, and the default mobile session config
- `mkosi.repart/`: partition layout fragments for the raw disk image
- `mkosi.postinst*` and `mkosi.finalize`: post-install and final image hooks
- `mkosi.packages/`: local RPMs made available to mkosi during the build

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

To inspect the XFCE variant:
```sh
mkosi --profile xfce summary
```

## Build
Build the image using mkosi with the provided configuration:
```sh
sudo mkosi -f build
```

Build the XFCE image for the low-power target:
```sh
sudo mkosi --profile xfce -f build
```

## To validate the rootfs
You can login into the built image to validate its contents:
```sh
sudo mkosi shell
```

To validate the XFCE variant:
```sh
sudo mkosi --profile xfce shell
```

## Desktop Variants
- Default build: Plasma Mobile on Fedora 43, output file `fedora43.raw`
- XFCE profile: lightweight Fedora 43 desktop variant, output file `fedora43-xfce.raw`

The XFCE variant installs Fedora's `@xfce-desktop-environment` group and overrides `greetd` to start `startxfce4` for the `mecha` user instead of the default `phoc --exec mechanix-launcher` mobile session.
