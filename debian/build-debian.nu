#!/usr/bin/env nu

# imports
use modules/logger.nu *
use modules/pkg.nu *
use modules/network-config.nu *
use modules/audio-config.nu *
use modules/os-config.nu *
use modules/boot-config.nu *
use modules/system-config.nu *
use modules/user-config.nu *
use modules/kernel-config.nu *
use modules/pack-rootfs.nu *



const PACKAGE_CONF_PATH = "./conf/build.yml"

# Global aliases
alias SUDO = sudo
alias CHROOT = sudo chroot

# Global variables
const TARGET_HOSTNAME = "mecha-comet-m"
const TARGET_LOCALE = "en-US.UTF-8"
const TARGET_TIMEZONE = "America/Los_Angeles"

# Entrypoint
def main [machine: string, build_dir: string] {
  log_info "Building Mechanix (Debian)\n"

  let work_dir = $build_dir + "/work"
  let deploy_dir = $build_dir + "/deploy"
  let tmp_dir = $work_dir + "/tmp"
  let rootfs_dir = $deploy_dir + "/rootfs"

  log_info $"Rootfs Directory: ($rootfs_dir)"
  log_info "Build Configuration:"
  log_info $"BUILD_DIR: ($build_dir)"
  log_info $"WORK_DIR: ($work_dir)"
  log_info $"DEPLOY_DIR: ($deploy_dir)\n"

  # Make build directories
  mkdir $build_dir
  mkdir $work_dir
  mkdir $deploy_dir
  mkdir $tmp_dir

  ## Set environment variables
  load-env {
    MACHINE: $machine,
    BUILD_DIR: $build_dir,
    WORK_DIR: $work_dir,
    DEPLOY_DIR: $deploy_dir,
    TMP_DIR: $tmp_dir,
    ROOTFS_DIR: $rootfs_dir,
    # LC_ALL: "C",
    # LANGUAGE: "C",
    # LANG: "C"
  }

  # TODO: handle return code handling, create a stages runner

  # Stage1: Setup rootfs
  # install_host_packages
  # debootstrap
  # copy_qemu_arm_static
  # make_root_home_dir
  # mount_sys_proc_volumes
  # install_linux_firmware_packages
  # install_linux_kernel_packages
  # install_target_packages
  # log_info "setting up rootfs:"
  
  # set_hostname # disabled
  # setup_default_locale_timezone # disabled
  # copy_linux_kernel_dtb_modules # disabled
  # copy_linux_kernel_dtb_modules $rootfs_dir $PACKAGE_CONF_PATH # disabled
  
  # copy_misc
  # configure_audio $rootfs_dir $PACKAGE_CONF_PATH
  # update_os_release $rootfs_dir $PACKAGE_CONF_PATH
  # configure_udev $rootfs_dir $PACKAGE_CONF_PATH
  # configure_networking $rootfs_dir
  # enable_easysplash $rootfs_dir # disabled
  # enable_boot_fw # disabled
  # configure_bluetooth $rootfs_dir $PACKAGE_CONF_PATH
  # configure_ssh $rootfs_dir $PACKAGE_CONF_PATH
  # configure_default_user $rootfs_dir $PACKAGE_CONF_PATH
  # configure_greeter $rootfs_dir
  # configure_sys_files $rootfs_dir $PACKAGE_CONF_PATH
  unmount_sys_proc_volumes
  pack_root_fs $rootfs_dir $deploy_dir
}

def debootstrap [] {
  log_info "Debootstrapping debian:"
  let work_dir = $env.WORK_DIR;
  let tmp_dir = $env.TMP_DIR;
  let deploy_dir = $env.DEPLOY_DIR;
  let rootfs_dir = $env.ROOTFS_DIR;

  # Check if `debootstrap` is installed
  let $is_deboostrap_installed = dpkg -l | grep debootstrap | length

  # Install `debootstrap` package, if not installed
  # if $is_deboostrap_installed == 0 {
  #   log_error "`debootstrap` is not installed, cannot continue further."
  #   return
  # }
 
  # TODO: uncomment
  SUDO debootstrap --arch arm64 --foreign --no-check-gpg --include=eatmydata,gnupg bookworm $rootfs_dir http://deb.debian.org/debian
  CHROOT $rootfs_dir /debootstrap/debootstrap --second-stage
}

def copy_qemu_arm_static [] {
  log_info "Copying qemu-arm-static:"

  let rootfs_dir = $env.ROOTFS_DIR

  # Check if `debootstrap` is installed
  let is_qemu_arm_static_installed = dpkg -l | grep qemu-user-static | wc -l | into int

  # TODO: instead of checking with dpkg we can check with binary
  if $is_qemu_arm_static_installed == 0 {
    log_error "`qemu-user-static` is not installed, cannot continue further"
    return
  }

  SUDO cp /usr/bin/qemu-arm-static $"($rootfs_dir)/usr/bin/"
}

def make_root_home_dir [] {
  log_info "Setting up root homedir:"
  let rootfs_dir = $env.ROOTFS_DIR

  CHROOT $rootfs_dir mkdir -p $"/home/root"
}

def mount_sys_proc_volumes [] {
  log_info "Mouting sys, proc volumes:"
  
  let rootfs_dir = $env.ROOTFS_DIR

  SUDO mount sysfs $"($rootfs_dir)/sys" -t sysfs
  SUDO mount proc $"($rootfs_dir)/proc" -t proc
}

# def set_hostname [] {
#   log_info "Setting hostname:"
#   let rootfs_dir = $env.ROOTFS_DIR

#   CHROOT $rootfs_dir hostnamectl set-hostname $TARGET_HOSTNAME
# }



def unmount_sys_proc_volumes [] {
  log_info "Unmounting sys, proc volumes:"

  let rootfs_dir = $env.ROOTFS_DIR

  SUDO umount $"($rootfs_dir)/sys"
  SUDO umount $"($rootfs_dir)/proc"
}

def setup_default_locale_timezone [] {
  log_info "Setting up default locale, timezone:"
  let rootfs_dir = $env.ROOTFS_DIR
  

  CHROOT $rootfs_dir localectl set-locale $"LANG=($TARGET_LOCALE)"
  CHROOT $rootfs_dir timedatectl set-timezone $TARGET_TIMEZONE

  # TODO: Why is this disabled
  #$CHROOTCMD systemctl enable systemd-timesyncd
}



def copy_misc [] {
  log_info "Copying miscellaneous files:"


  let rootfs_dir = $env.ROOTFS_DIR
  alias CHROOT = sudo chroot $rootfs_dir

  CHROOT dpkg -R --force-all -i /tmp
  
}



