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

export def boot_script [rootfs_dir: string, package_conf_path: string] {
  log_info "Setting boot script:"

  alias CHROOT = sudo chroot $rootfs_dir
  alias SUDO = sudo
  let script_dir_path =  (open $package_conf_path | get scripts-path)
  logger log_debug $"Script Directory Path: ($script_dir_path)"

  # /home/jack/Desktop/mecha/mecha-make/temp/build-debian/include/scripts/boot.script
  # /home/jack/Desktop/mecha/mecha-make/debian/include/scripts/boot.script

  let boot_script_src = $script_dir_path + "/boot.script"
  let boot_src = $script_dir_path + "/boot.scr"
  
  mkimage -c none -A arm -T script -d $boot_script_src $boot_src

  let boot_script_dest = $rootfs_dir + "/boot/boot.scr"

  SUDO cp $boot_src $boot_script_dest

}