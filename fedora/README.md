# Mechanix OS - Debian-based Linux Distribution for mecha comet m

## Overview

Mechanix OS is a custom Debian-based Linux distribution designed specifically for mecha comet m, built using Nushell (nu) scripting language. The project provides a flexible and modular approach to creating embedded Linux systems.

## Key Features

- Modular build system using Nushell
- Customizable for different ARM machine targets
- Automated package installation
- Comprehensive system configuration
- Support for custom package sources
- Integrated logging and error handling

## Prerequisites

- Nushell (nu)
- Docker (for containerized builds)
- qemu-user-static
- Debian-based host system

## Build Process

### Build Command

```bash
nu build-debian.nu <machine-target> <build-directory>
```

### Example

```bash
nu build-debian.nu mecha-comet-m-gen1 /path/to/build/assets
```

## Build Stages

### The build process includes several key stages:


1. Pre-condition Setup
   - Debootstrap Debian base system
   - Copy QEMU ARM static binary

2. System Configuration
    - Network configuration
    - Package source management
    - Boot script setup
    - Package installation
    - Audio configuration
    - Bluetooth setup
    - SSH configuration
    - User account creation

 3. Finalization
    - System file configuration
    - Root filesystem packaging

 4. Configuration Files
    - conf/build.yml
    - conf-packages/host.yml and conf-packages/target.yml

5. Customization
    - Build configuration in conf/build.yml
    - Package lists in conf-packages/
    - Module scripts in modules/
    - Include files in include/

6. Troubleshooting
    - Ensure qemu-arm-static is installed
    - Check build logs for detailed error information
    - Verify configuration files are correctly formatted

7. Contributing
    - Fork the repository
    - Create a new branch
    - Make changes
    - Submit a pull request

