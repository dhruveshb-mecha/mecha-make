#!/usr/bin/env nu

use logger.nu


export def enable_easysplash [rootfs_dir: string] {

  log_info "Enabling easysplash service:"

  alias CHROOT = sudo chroot $rootfs_dir
  alias SUDO = sudo
  CHROOT systemctl enable easysplash-start.service
  CHROOT systemctl enable easysplash-quit.service

  log_debug "Enabling easysplash service Successfully."
  # $CHROOTCMD systemctl enable easysplash-start.service
  # $CHROOTCMD systemctl enable easysplash-quit.service
}

export def enable_boot_fw [rootfs_dir: string] {
  log_info "Enabling boot-fw service:"


  alias CHROOT = sudo chroot $rootfs_dir

  CHROOT systemctl enable boot-fw.service
  CHROOT systemctl enable boot-fw-quit.service


  log_debug "Enabling boot-fw service Successfully."

  # sudo cp $ROOTDIR/../../scripts/fw_env.config $ROOTDIR/etc
  # sudo cp $ROOTDIR/../../scripts/u-boot-initial-env $ROOTDIR/etc
}