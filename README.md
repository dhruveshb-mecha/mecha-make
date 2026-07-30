# Mechanix OS Build System

Build system for creating custom Linux distributions and bootloaders for Mecha Comet devices.

## Overview

This repository contains mkosi configuration and assets to build a reproducible Fedora-based image for the "mecha" project.

Configuration layout:

- `mkosi.conf` - distribution, output, and boot settings.
- `mkosi.conf.d/` - package lists, split by category (base, hardware, desktop, multimedia, mechanix apps). Merged automatically with `mkosi.conf`.
- `mkosi.profiles/` - opt-in variants selected with `--profile=<name>`, layered on top of the default build (see "Build" below).
- `mkosi.version` - the image version, bumped with `mkosi bump` or `mkosi -B build` (`--auto-bump`).

## Prerequisites

- Ubuntu/Debian (or other Linux host)
- mkosi
- qemu (for cross-arch or image testing)
- ovmf (UEFI firmware, needed to boot the `qemu` profile image - see "Testing in QEMU" below)
- debootstrap (if building Debian/Ubuntu images)

Install common dependencies:

```sh
sudo apt update
sudo apt install -y mkosi qemu-system-x86 ovmf debootstrap
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
ships locked too. This doesn't affect the Phosh session on the device
screen, which greetd auto-starts as `mecha` regardless (see
`mkosi.skeleton/etc/greetd/config.toml`).

Separately, `Autologin=yes` in `mkosi.conf` is mkosi's own setting for
passwordless **root** autologin on `tty1`/`hvc0`/nspawn's `pts/0` - i.e. an
unauthenticated root shell on the physical/serial console. It's on by
default for local development convenience; build with `--profile=release`
(see "Build" below) to disable it.

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

For a build with root's tty1/serial-console autologin disabled, select the
`release` profile:

```sh
sudo mkosi --profile=release -f build
```

## To validate the rootfs

You can login into the built image to validate its contents:

```sh
sudo mkosi shell
```

## Testing in QEMU

Mecha Comet hardware is arm64-only, but the `qemu` profile (`mkosi.profiles/qemu.conf`)
builds a minimal x86-64 image for local testing under QEMU: generic Fedora
kernel instead of the Comet kernel/devicetree, and no Comet hardware or
Mechanix app packages (neither is built for x86-64) - just the base system
plus phoc/phosh, enough to boot to a real Phosh session.

### Download a prebuilt image

Don't want to build it yourself? The `.github/workflows/qemu-image-build.yml`
workflow builds this image and uploads it as a workflow artifact on every
push (and via manual "Run workflow"). To grab one: open the
[Actions tab](../../actions/workflows/qemu-image-build.yml), pick a
successful run, and download the `mechanix-os-qemu-raw` and
`run-qemu-standalone` artifacts from its summary page (requires being signed
in to GitHub with access to this repo - artifacts aren't public downloads).
Each artifact is a zip containing one file; unzip both into the same empty
directory, then:

```sh
sudo apt install -y qemu-system-x86 qemu-system-gui ovmf   # one-time host setup
chmod +x run-qemu-standalone.sh
./run-qemu-standalone.sh
```

Autologin is on by default, so it boots straight to a Phosh session with no
password needed.

### Quick start (building it yourself)

```sh
./run-qemu.sh          # builds mechanix-os-qemu.raw if it doesn't exist yet, then boots it
./run-qemu.sh --build  # forces a rebuild first (clean + build), then boots
```

That script is the whole workflow end to end - it builds the image, refreshes
a scratch copy of the OVMF UEFI variables store, and launches QEMU with the
flags this profile needs (see below). Requires `qemu-system-x86`,
`qemu-system-gui`, and `ovmf` installed on the host:

```sh
sudo apt install -y qemu-system-x86 qemu-system-gui ovmf
```

### Why not `mkosi vm`?

Normally `mkosi --profile=qemu vm` would build and boot in one step. It
doesn't work here: this profile's tools tree is Fedora (see `mkosi.conf`'s
`[Build]` section), and running that Fedora-built qemu binary through
mkosi's own sandbox segfaults as soon as a graphical display is requested.
This is a known, currently-unfixed upstream bug -
[mkosi#3941](https://github.com/systemd/mkosi/issues/3941). `run-qemu.sh`
sidesteps it entirely by calling the host's own `qemu-system-x86_64`
directly against the built `.raw` disk image (booting it via OVMF/UEFI +
systemd-boot, exactly like real hardware would) instead of going through
`mkosi vm`.

### What each QEMU flag is for

- `-machine q35 -cpu host -smp 4 -m 4096`: 4 vCPUs / 4GB RAM to roughly match
  the real Comet's quad-core Cortex-A53 + 4GB LPDDR4. Everything else on the
  real SoC (the Vivante GPU, the 2.3 TOPS NPU, the camera ISP, WiFi/BT/4G
  modem, sensors, haptics, battery, security enclave) has no x86 QEMU
  equivalent and isn't attempted - this is for verifying UI layout, phoc/phosh
  behavior, and general app functionality, not hardware-accurate testing.
- `-drive if=pflash,...OVMF_CODE_4M.fd` / `OVMF_VARS_4M.fd`: UEFI firmware,
  needed since the image boots via `Bootloader=systemd-boot`.
- `-display gtk,gl=on,zoom-to-fit=on -device virtio-vga-gl,xres=1080,yres=1240`:
  a GL-accelerated display sized to the real Comet DSI panel's resolution
  (1080x1240). Plain `virtio-vga` without `gl=on` works too but visibly
  flickers (no vsync on the software-framebuffer path); `zoom-to-fit=on` lets
  you resize the window without it staying locked to 1080x1240 physical
  pixels (which looks tiny on a normal monitor).
- `-device qemu-xhci,id=xhci -device usb-tablet,bus=xhci.0 -device usb-kbd,bus=xhci.0`:
  a USB controller with an absolute-position tablet (closer to touch input
  than a relative PS/2 mouse - Phosh's UI is designed around tap-to-position)
  plus a keyboard.

Two more things are baked into the image itself for the `qemu` profile (see
`mkosi.postinst.chroot`, gated on `$PROFILES` so they never affect the real
Comet build):

- **Display geometry**: phosh's packaged `/usr/share/phosh/phoc.ini` gives
  the `Virtual-1` output (the DRM connector name paravirtualized GPUs like
  `virtio-vga` register as) an arbitrary `720x1440@scale=2` placeholder.
  It's replaced with `1080x1240@scale=1` to match the real DSI-1 panel's
  resolution.
- **Cursor fix**: `virtio-gpu-gl`'s hardware cursor plane renders Y-flipped
  through wlroots (the same bug hits other wlroots compositors, e.g. sway,
  under QEMU GL - not phoc-specific). `WLR_NO_HARDWARE_CURSORS=1` is set via
  `/etc/environment.d/` to force software cursor compositing instead.

### Multitouch and other input limits

QEMU's input devices (`usb-tablet`/mouse) are single-pointer only.
