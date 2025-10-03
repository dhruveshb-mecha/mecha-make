# Mechanix OS Build System

A modular, Nushell-based build system for creating custom Linux distributions and bootloaders for Mecha Comet devices.

## Overview

Mechanix OS provides a flexible and automated build system that enables developers to build complete Linux distributions, custom kernels, and bootloaders for Mecha Comet hardware. The entire build system is written in Nushell (nu), providing a modern scripting approach with strong typing and error handling.

## Supported Components

- **Debian-based Linux Distribution** — Custom Debian builds optimized for Mecha Comet
- **Fedora-based Linux Distribution** — Custom Fedora builds optimized for Mecha Comet
- **Linux Kernel** — Custom kernel builds with device-specific configurations
- **U-Boot Bootloader** — Customized U-Boot with ARM Trusted Firmware support

## Prerequisites

### Required Software

- [Nushell](https://www.nushell.sh/) (nu shell)
- Docker
- qemu-user-static
- Git

### For Kernel Builds

- ARM cross-compilation toolchain (`aarch64-linux-gnu-`)
- Build essentials (`gcc`, `make`, etc.)
- Kernel build dependencies

### For U-Boot Builds

- ARM cross-compilation toolchain (`aarch64-linux-gnu-`)
- Device Tree Compiler (`dtc`)
- Build essentials

## How It Works

Each build system (Debian, Kernel, U-Boot) is organized as a separate project directory, and each contains:

- **A dedicated Dockerfile**: This Dockerfile sets up a container with all the essential tools and dependencies required for building that component. For example:
    - The Debian build system's Dockerfile includes everything needed to build a custom root filesystem.
    - The Kernel build system's Dockerfile provides the necessary cross-compilers and kernel build tools.
    - The U-Boot build system's Dockerfile contains tools for bootloader compilation and device tree generation.

- **A Nushell build script**: Each project directory has its own Nushell script (`build.nu` or similar) that automates the build process inside the prepared Docker environment.

### Build Process Overview

1. **Prepare the Environment**: The Dockerfile in each directory is used to build a container image with all required tools.
2. **Run the Build Script**: The Nushell script is executed (typically via `nu build ...`), which orchestrates the build steps inside the container.
3. **Generate Artifacts**: The build script produces the final output (rootfs, kernel image, U-Boot binary) in the designated build directory.

This modular approach ensures that each component is built in a clean, reproducible environment tailored to its specific requirements.

## Project Structure

```
.
├── debian/          # Debian distribution build system
├── kernel/          # Linux kernel build system
├── uboot/           # U-Boot bootloader build system
└── LICENSE          # Project license
```

## Build Artifacts

Build artifacts (ISO images, kernel images, bootloader binaries) will be located in the specified build directory after successful builds. The structure is as follows:

```
<build-directory>/
├── work/            # Temporary build files
└── deploy/          # Final build artifacts
    ├── rootfs/      # Root filesystem (for distro builds)
    ├── Image        # Kernel image (for kernel builds)
    ├── *.dtb        # Device tree blobs (for kernel builds)
    └── flash.bin    # U-Boot image (for U-Boot builds)
```

## Documentation

Each component has its own detailed README:

- [Debian Build System](../debian/README.md)
- [Kernel Build System](../kernel/README.md)
- [U-Boot Build System](../uboot/README.md)

## Contributing

We welcome contributions! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request