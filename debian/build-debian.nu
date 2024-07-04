#!/usr/bin/env nu

# imports
use modules/logger.nu *
use modules/pkg.nu *
use modules/network-config.nu *
use modules/audio-config.nu *
use modules/distro-config.nu *
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
    let distro_dir = $work_dir + "/distro"
    let tmp_dir = $work_dir + "/tmp"
    let rootfs_dir = $distro_dir + "/rootfs"

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
        LC_ALL: "C",
        LANGUAGE: "C",
        LANG: "C"
    }

    try {
       # Stage1: Setup and Initialization
    setup_environment

    # Stage2: Root Filesystem Preparation
    prepare_rootfs

    # Stage3: Installing Target Packages
    install_packages

    # Stage4: Root Filesystem Configuration
    configure_rootfs

    # Stage5: Packing the Root Filesystem
    pack_rootfs

    # Stage6: Cleanup
    cleanup
       
    } catch {
        |err|
        log_error $"Failed to build Mechanix: ($err)"
        ensure_unmount
    }
    


}

def setup_environment [] {
    log_info "Setting up environment:"
    install_host_packages
}

def prepare_rootfs [] {
    log_info "Preparing root filesystem:"
    debootstrap
    copy_qemu_arm_static
    make_root_home_dir
}

def install_packages [] {
    log_info "Installing target packages:"
    mount_sys_proc_volumes
    install_target_packages
}

def configure_rootfs [] {
    log_info "Configuring root filesystem:"
    # set_hostname
    # setup_default_locale_timezone
    copy_linux_kernel_dtb_modules $env.ROOTFS_DIR $PACKAGE_CONF_PATH
    copy_misc
    configure_audio $env.ROOTFS_DIR $PACKAGE_CONF_PATH
    distro_info $env.ROOTFS_DIR $PACKAGE_CONF_PATH
    configure_udev $env.ROOTFS_DIR $PACKAGE_CONF_PATH
    configure_networking $env.ROOTFS_DIR
    enable_easysplash $env.ROOTFS_DIR
    configure_bluetooth $env.ROOTFS_DIR $PACKAGE_CONF_PATH
    configure_ssh $env.ROOTFS_DIR $PACKAGE_CONF_PATH
    configure_default_user $env.ROOTFS_DIR $PACKAGE_CONF_PATH
    configure_greeter $env.ROOTFS_DIR
    configure_sys_files $env.ROOTFS_DIR $PACKAGE_CONF_PATH
}

def pack_rootfs [] {
    log_info "Packing root filesystem:"
    pack_root_fs $env.ROOTFS_DIR $env.DEPLOY_DIR
}

def cleanup [] {
    log_info "Cleaning up:"
    unmount_sys_proc_volumes
}

def debootstrap [] {
    log_info "Debootstrapping Debian:"
    let work_dir = $env.WORK_DIR;
    let tmp_dir = $env.TMP_DIR;
    let deploy_dir = $env.DEPLOY_DIR;
    let rootfs_dir = $env.ROOTFS_DIR;

    let $is_deboostrap_installed = dpkg -l | grep debootstrap | length

    SUDO debootstrap --arch arm64 --foreign --no-check-gpg --include=eatmydata,gnupg bookworm $rootfs_dir http://deb.debian.org/debian
    CHROOT $rootfs_dir /debootstrap/debootstrap --second-stage
}

def copy_qemu_arm_static [] {
    log_info "Copying qemu-arm-static:"

    let rootfs_dir = $env.ROOTFS_DIR
    let is_qemu_arm_static_installed = dpkg -l | grep qemu-arm-static | wc -l | into int

    if $is_qemu_arm_static_installed == 0 {
        log_error "`qemu-arm-static` is not installed, cannot continue further"
        return
    }

    SUDO cp /usr/bin/qemu-arm-static $"($rootfs_dir)/usr/bin/"
}

def make_root_home_dir [] {
    log_info "Setting up root home directory:"
    let rootfs_dir = $env.ROOTFS_DIR
    CHROOT $rootfs_dir mkdir -p $"/home/root"
}

def mount_sys_proc_volumes [] {
    log_info "Mounting sys, proc volumes:"
    let rootfs_dir = $env.ROOTFS_DIR
    SUDO mount sysfs $"($rootfs_dir)/sys" -t sysfs
    SUDO mount proc $"($rootfs_dir)/proc" -t proc
}

# def set_hostname [] {
#     log_info "Setting hostname:"
#     let rootfs_dir = $env.ROOTFS_DIR
#     CHROOT $rootfs_dir hostnamectl set-hostname $TARGET_HOSTNAME
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
}

def copy_misc [] {
    log_info "Copying miscellaneous files:"
    let rootfs_dir = $env.ROOTFS_DIR
    alias CHROOT = sudo chroot $rootfs_dir
    CHROOT dpkg -R --force-all -i /tmp
}


def ensure_unmount [] {
  log_info "Ensuring all volumes are unmounted"
  try {
    unmount_sys_proc_volumes
  } catch {
    |err| 
    log_warn $"Failed to unmount volumes: ($err)"
  }
}