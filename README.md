# Mechanix OS Build System

Build system for creating Fedora-based images for Mecha Comet devices using `mkosi`.

## Repository Layout

- `mkosi.conf` – Base mkosi configuration.
- `mkosi.conf.d/` – Package groups and additional configuration.
- `mkosi.profiles/` – Build profiles such as `comet`, `release`, and `qemu`.
- `mkosi.skeleton/` – Files copied into the image before the package manager runs.
  Note: with incremental builds, skeleton changes need a full rebuild (`-ff`).
- `mkosi.extra.comet/` – Comet-only files copied in after the OS is installed
  (USB gadget service, dnsmasq config). Applied on every build.
- `mkosi.version` – Image version.
- `build.sh` – Rootless, containerized build wrapper (see below).

## Prerequisites

Install the required tools:

```sh
sudo apt update
sudo apt install -y mkosi qemu-system-x86 ovmf debootstrap
```

## View Configuration

Show the current mkosi configuration:

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
ships locked too. This doesn't affect the labwc session on the device
screen, which greetd auto-starts as `mecha` regardless (see
`mkosi.skeleton/etc/greetd/config.toml`).

Separately, `Autologin=yes` in `mkosi.conf` is mkosi's own setting for
passwordless **root** autologin on `tty1`/`hvc0`/nspawn's `pts/0` - i.e. an
unauthenticated root shell on the physical/serial console. It's on by
default for local development convenience; build with the `release` profile
(see "Build" below) to disable it.
## Development Credentials

The root account is disabled.

A regular user named `mecha` is created during the build.

To set a password for development:

```sh
echo "MECHA_USER_PASSWORD=YOUR_PASSWORD" > mkosi.env
chmod 600 mkosi.env
```

Do not commit `mkosi.env`.

## Build

A profile is always required.

### Host-installed mkosi

```sh
sudo mkosi --profile=comet -f build
```

Build a release image:

```sh
sudo mkosi --profile=comet,release -f build
```

### Containerized

`./build.sh` builds inside a podman container and stamps the image version + commit SHA:

```sh
./build.sh                     # incremental comet build (mkosi -f)
./build.sh --force             # full rebuild (mkosi -ff)
./build.sh --profile=qemu      # other profiles
./build.sh --version=20260813-1200   # override the IMAGE_VERSION stamp
```

Incremental builds cache the package-install step. After editing `mkosi.skeleton/`, rebuild with `--force` (`-ff`).

## Inspect the Image

Open a shell inside the built image:

```sh
sudo mkosi shell
```

## Test in QEMU

Mecha Comet hardware is arm64-only, but the `qemu` profile (`mkosi.profiles/qemu.conf`)
builds a minimal x86-64 image for local testing under QEMU: generic Fedora
kernel instead of the Comet kernel/devicetree, and no Comet hardware or
Mechanix app packages (neither is built for x86-64) - just the base system
plus labwc/kanshi/wofi, enough to boot to a real labwc session.

### Download a prebuilt image

Don't want to build it yourself? The `.github/workflows/qemu-image-build.yml`
workflow builds this image and uploads it as a workflow artifact on every
push (and via manual "Run workflow"). To grab one: open the
[Actions tab](../../actions/workflows/qemu-image-build.yml), pick a
successful run, and download the `mechanix-os-qemu-raw` and `run-qemu`
artifacts from its summary page (requires being signed in to GitHub with
access to this repo - artifacts aren't public downloads). Each artifact is
a zip containing one file; unzip both into the same empty directory, then:
Build and boot the QEMU image:

```sh
./run-qemu.sh
```

(`run-qemu.sh` is the same script as "Quick start" below - run standalone
like this, with no `mkosi.conf` next to it, it detects there's no mkosi
checkout to build from and just boots the downloaded image.)

Autologin is on by default, so it boots straight to a labwc session with no
password needed.

### Quick start (building it yourself)
Force a rebuild before booting:

```sh
./run-qemu.sh --build
```

If you only want to boot a prebuilt image from GitHub Actions, download the `mechanix-os-qemu-raw` and `run-qemu` artifacts, extract them into the same directory, and run:

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
  equivalent and isn't attempted - this is for verifying UI layout, labwc/wofi
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
  a USB controller with an absolute-position tablet (closer to the device's
  touchscreen than a relative PS/2 mouse) plus a keyboard.

One more thing is baked into the image itself for the `qemu` profile (see
`mkosi.postinst.chroot`, gated on `$PROFILES` so it never affects the real
Comet build):

- **Cursor fix**: `virtio-gpu-gl`'s hardware cursor plane renders Y-flipped
  through wlroots (the same bug hits other wlroots compositors, e.g. sway,
  under QEMU GL - not labwc-specific). `WLR_NO_HARDWARE_CURSORS=1` is set via
  `/etc/environment.d/` to force software cursor compositing instead.

Output scaling (`scale=2`) is handled uniformly for both profiles by kanshi
(`mkosi.skeleton/etc/xdg/kanshi/config`, autostarted from
`mkosi.skeleton/etc/xdg/labwc/autostart`) rather than a qemu-specific
override, so the `qemu` profile's virtual display now renders at the same
scale as the real Comet DSI panel - it'll look larger in the QEMU window
than the old phoc-based `Virtual-1@scale=1` override did.

### Multitouch and other input limits

QEMU's input devices (`usb-tablet`/mouse) are single-pointer only.
chmod +x run-qemu.sh
./run-qemu.sh
```

## SSH over USB-C

The comet image exposes a USB ethernet gadget (`usb0` = `172.16.42.1/24`) on
the USB-C/PD port. Use `ssh mecha@172.16.42.1` to connect to the device. Only enabled for the comet profile.
