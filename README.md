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

## Credentials

**Root has no password and no login, by design** - `RootPassword=hashed:!!`
in `mkosi.conf` permanently locks the account. This isn't configurable and
matches how KDE Linux (and most modern systemd-based distros) handle root:
all administrative access goes through a regular sudo user instead.

That user is `mecha` (created in `mkosi.postinst.chroot`, member of `wheel`).
No password for it is committed to this repository either - by default it
ships locked too (console autologin via `Autologin=yes` doesn't need one).

To set a password for local development or testing, create this gitignored
file in the repo root before building:

```sh
echo "MECHA_USER_PASSWORD=YOUR_SECURE_PASSWORD" > mkosi.env
chmod 600 mkosi.env
```

Never commit this file or put real credentials in `mkosi.conf` or
`mkosi.postinst.chroot`.

### CI-built images

The GitHub Actions workflow writes this same file from a repository secret
(`CI_MECHA_USER_PASSWORD`) before building, so uploaded artifacts stay
testable without any credential living in git history. If that secret isn't
configured, CI images fall back to the same locked default as a local build
without `mkosi.env`.

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
