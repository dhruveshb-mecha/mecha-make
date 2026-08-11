# Mechanix OS Build System

Build system for creating Fedora-based images for Mecha Comet devices using `mkosi`.

## Repository Layout

- `mkosi.conf` – Base mkosi configuration.
- `mkosi.conf.d/` – Package groups and additional configuration.
- `mkosi.profiles/` – Build profiles such as `comet`, `release`, and `qemu`.
- `mkosi.version` – Image version.

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

Build a Comet image:

```sh
sudo mkosi --profile=comet -f build
```

Build a release image:

```sh
sudo mkosi --profile=comet,release -f build
```

## Inspect the Image

Open a shell inside the built image:

```sh
sudo mkosi shell
```

## Test in QEMU

Build and boot the QEMU image:

```sh
./run-qemu.sh
```

Force a rebuild before booting:

```sh
./run-qemu.sh --build
```

If you only want to boot a prebuilt image from GitHub Actions, download the `mechanix-os-qemu-raw` and `run-qemu` artifacts, extract them into the same directory, and run:

```sh
chmod +x run-qemu.sh
./run-qemu.sh
```
