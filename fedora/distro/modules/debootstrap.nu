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
  log_info $"Installing minimal Fedora $fedora_ver rootfs to ($rootfs_dir)..."
  SUDO dnf --assumeyes --releasever=$fedora_ver \
    --installroot=$rootfs_dir \
    --setopt=install_weak_deps=False \
    --setopt=tsflags=nodocs \
    --nogpgcheck \
    --use-host-config \
    install \
    @core \
    dnf \
    rpm \
    bash \
    glibc-langpack-en \
    passwd \
    shadow-utils \
    hostname \
    systemd \
    vim-minimal\
    nano \
    coreutils 

  # Clean up unnecessary files
  SUDO dnf --installroot=$rootfs_dir --assumeyes clean all



  # Set default shell to bash
  SUDO ln -sf /bin/bash $"($rootfs_dir)/bin/sh"

  log_info "Fedora rootfs created successfully."
}