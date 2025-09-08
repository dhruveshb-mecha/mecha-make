# Mechanix OS - Fedora 42-based Linux Distribution for mecha comet m

## Overview

Mechanix OS is a custom Fedora 42-based Linux distribution designed specifically for mecha comet m, built using Nushell (nu) scripting language. The project provides a flexible and modular approach to creating embedded Linux systems with the power and modern features of Fedora.

## Key Features

- Modular build system using Nushell
- Customizable for different ARM machine targets
- Automated package installation with DNF
- Comprehensive system configuration
- Support for custom RPM repositories
- Integrated logging and error handling
- Modern systemd integration
- SELinux support
- Latest kernel and drivers

## Prerequisites

- Nushell (nu)
- Docker (for containerized builds)
- qemu-user-static
- Fedora-based host system (recommended)
- DNF package manager
- Mock build system (optional, for advanced builds)

## Build Process

### Build Command

```bash
nu build-fedora.nu <machine-target> <build-directory>
```

### Example

```bash
nu build-fedora.nu mecha-comet-m-gen1 /path/to/build/assets
```

## Build Stages

### The build process includes several key stages:

1. **Pre-condition Setup**
   - Bootstrap Fedora 42 base system using DNF
   - Copy QEMU ARM static binary
   - Set up chroot environment
   - Configure RPM database

2. **System Configuration**
   - Network configuration (NetworkManager)
   - Repository management (/etc/yum.repos.d/)
   - Boot script setup (systemd services)
   - Package installation via DNF
   - Audio configuration (PipeWire/ALSA)
   - Bluetooth setup (BlueZ)
   - SSH configuration (OpenSSH)
   - User account creation
   - SELinux policy configuration
   - Firewall setup (firewalld)

3. **Finalization**
   - System file configuration
   - Kernel module configuration
   - Root filesystem packaging
   - Boot loader configuration (GRUB2/U-Boot)

4. **Configuration Files**
   - `conf/build.yml` - Main build configuration
   - `conf-packages/host.yml` - Host system packages
   - `conf-packages/target.yml` - Target system packages
   - `conf-repos/fedora.yml` - Repository configuration
