#!/usr/bin/env nu

use logger.nu

alias SUDO = sudo
alias CHROOT = sudo chroot

export def dnfstrap_fedora [] {
  log_info "Bootstrapping Fedora rootfs:"
  let work_dir = $env.WORK_DIR;
  let tmp_dir = $env.TMP_DIR;
  let deploy_dir = $env.DEPLOY_DIR;
  let rootfs_dir = $env.ROOTFS_DIR;
  let BUILD_CONF_PATH = $env.BUILD_CONF_PATH;

  # Check if `dnf` is installed
  let dnf_installed = not (which dnf | is-empty)
  if not $dnf_installed {
    log_error "`dnf` is not installed, cannot continue further."
    return
  }

  let fedora_ver = open $BUILD_CONF_PATH | get fedora | get version
  let arch = open $BUILD_CONF_PATH | get fedora | get arch

  # Create the rootfs with dnf
  log_info $"Installing minimal Fedora ($fedora_ver) rootfs to ($rootfs_dir)..."
  let dnf_args = [
    "--assumeyes"
    $"--releasever=42"
    $"--installroot=/build/assets/deploy/rootfs/"
    "--setopt=install_weak_deps=False"
  "--setopt=tsflags=nodocs"
  "--nogpgcheck"
  "--use-host-config"
  "install"
  "@core"
  "dnf"
  "rpm"
  "bash"
  "glibc-langpack-en"
  "passwd"
  "shadow-utils"
  "hostname"
  "systemd"
  "vim-minimal"
  "nano"
  "coreutils"
]

  SUDO dnf ...$dnf_args

  # Clean up unnecessary files
  SUDO dnf --installroot=/build/assets/deploy/rootfs --assumeyes clean all



  # Set default shell to bash
  SUDO ln -sf /bin/bash /build/assets/deploy/rootfs/bin/sh

  log_info "Fedora rootfs created successfully."
}