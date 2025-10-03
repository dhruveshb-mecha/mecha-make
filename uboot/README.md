# Mechanix OS - U-Boot Bootloader Build System

## Overview

The U-Boot build system for Mechanix OS streamlines the process of building custom bootloaders for Mecha Comet devices. It integrates U-Boot, ARM Trusted Firmware (ATF), NXP i.MX firmware, and automates the creation of ready-to-flash bootloader images.

## Features

- Automated management of U-Boot source code
- Integration with ARM Trusted Firmware (ATF)
- Support for NXP i.MX8 firmware
- Automatic image generation using imx-mkimage
- DDR training firmware support
- Comprehensive bootloader packaging

## Prerequisites

- [Nushell (nu)](https://www.nushell.sh/)
- ARM64 cross-compilation toolchain:
    ```bash
    sudo apt-get install gcc-aarch64-linux-gnu
    ```
- U-Boot build dependencies:
    ```bash
    sudo apt-get install build-essential device-tree-compiler python3-dev python3-setuptools
    ```
- Git
- wget or curl (for firmware downloads)

## Getting Started

### Using Docker (Recommended)

```bash
# Build the Docker image
docker build -t mechanix-uboot .

# Run the build
docker run --rm -v $(pwd)/build:/build mechanix-uboot
```

The output will be in `./build/deploy/flash.bin`.

### Native Build

```bash
nu build.nu mecha-comet /path/to/build/directory
```

## Build Process

### Build Command

```bash
nu build.nu <machine-target> <build-directory>
```

#### Example

```bash
# Docker build
docker run --rm -v $(pwd)/build:/build mechanix-uboot

# Native build
nu build.nu mecha-comet ~/uboot-build
```

## What Gets Built

The build system creates a complete bootloader image (`flash.bin`) containing:

- U-Boot SPL (Secondary Program Loader)
- ARM Trusted Firmware (BL31 secure firmware)
- U-Boot (Main bootloader)
- Device Tree (Hardware configuration)

## Build Output

```
<build-directory>/
├── work/              # Temporary build files
│   ├── u-boot/        # U-Boot source
│   ├── imx-atf/       # ARM Trusted Firmware
│   └── imx-mkimage/   # Image generation tool
└── deploy/
        └── flash.bin      # Final bootloader (READY TO FLASH)
```

## Configuration

### Machine Configuration

Device-specific settings are in `machines/<machine-name>.yml`.