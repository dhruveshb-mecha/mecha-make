# Mechanix OS - Kernel Build System

### Overview
The Mechanix OS kernel build system provides an automated, containerized solution for building custom Linux kernels for Mecha Comet devices. Built with Nushell, it handles kernel compilation, module building, and Debian package generation for easy installation.

### Features

- Automated kernel compilation
- Module building and management
- Debian package generation
- Containerized build environment
- Device-specific defconfig support
- Modular Nushell-based build scripts

### Prerequisites

**Required**
- Docker Engine (20.10+)
- Git
- 4GB+ RAM available for Docker
- 15GB+ free disk space (kernel builds are large)

**Optional (for native builds)**
- Nushell (`nu`)
- ARM64 cross-compilation toolchain (`gcc-aarch64-linux-gnu`)
- Kernel build dependencies: `build-essential`, `bc`, `bison`, `flex`, `libssl-dev`, `libncurses-dev`

### Quick Start

**Using Docker (Recommended)**
```bash
# Build the Docker image
docker build -t mechanix-kernel .

# Run the build
docker run --rm -v $(pwd)/build:/build mechanix-kernel

# Kernel Image and DTBs will be in ./build/deploy/
# Debian packages will be in ./build/deploy/kernel/debs/
```

**Native Build**
```bash
nu build.nu mecha-comet /path/to/build/directory
```

### Build Process

**Build Command**
```bash
nu build.nu <machine-target> <build-directory>
```

**Example**
```bash
# Docker build
docker run --rm -v $(pwd)/build:/build mechanix-kernel

# Native build
nu build.nu mecha-comet ~/kernel-build
```

### What Gets Built

The build system produces:

- **Kernel Image** – Bootable Linux kernel (`Image`)
- **Device Tree Blobs** – Hardware description files (`*.dtb`)
- **Debian Packages** – Installable kernel packages:
    - `linux-image-*.deb` – Kernel binary and modules
    - `linux-headers-*.deb` – Headers for building external modules
    - `linux-libc-dev-*.deb` – Development headers

### Build Output

```
<build-directory>/
├── work/
│   ├── linux/              # Kernel source and build files
│   └── *.deb               # Generated Debian packages (moved to deploy)
└── deploy/
        ├── Image               # Kernel binary (READY TO USE)
        ├── mecha-comet-m*.dtb  # Device tree blobs
        └── kernel/
                └── debs/           # Debian packages (READY TO INSTALL)
                        ├── linux-headers-*.deb
                        ├── linux-image-*.deb
                        └── linux-libc-dev-*.deb
```

### Configuration

**Machine Configuration**

Device-specific settings are in `machines/<machine-name>.yml`


