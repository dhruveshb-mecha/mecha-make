#!/usr/bin/env nu

use logger.nu

alias SUDO = sudo

export def configure_networking [] {
    log_info "Configuring networking:"
    let rootfs_dir = $env.ROOTFS_DIR

    # List contents of the rootfs directory /etc
    log_debug $"Rootfs Directory: $rootfs_dir"

    log_debug "Listing contents of /etc in rootfs:"
    SUDO ls -l $"($rootfs_dir)/etc"

    # if resolv.conf already exists, remove it
    let resolv_conf_path = $"($rootfs_dir)/etc/resolv.conf"
    if ($resolv_conf_path | path exists) {
        log_debug "Removing existing resolv.conf"
        try {
            SUDO rm -f $resolv_conf_path
            log_debug "Removed existing resolv.conf"
        } catch { |err|
            log_error $"Failed to remove resolv.conf: ($err)"
        }
    }
    
    # Copy host's resolv.conf (remove destination first to handle symlinks)
    SUDO cp --remove-destination /etc/resolv.conf $resolv_conf_path

    # Copy host's environment and hosts files
    SUDO cp /etc/environment $"($rootfs_dir)/etc/environment"
    SUDO cp /etc/hosts $"($rootfs_dir)/etc/hosts"

    log_debug "Configuring networking: done"
}



export def configure_bluetooth [] {
log_info "Configuring bluetooth Service:"

let rootfs_dir = $env.ROOTFS_DIR
let build_conf_path = $env.BUILD_CONF_PATH

let script_dir_path =  (open $build_conf_path | get include-path)
alias CHROOT = sudo chroot $rootfs_dir

let bluetooth_hci_enable_service_src = $script_dir_path + "/bluetooth-hci-enable.service"
let bluetooth_hci_enable_service_dest = $rootfs_dir + "/lib/systemd/system/bluetooth-hci-enable.service"

let pulseaudio_bluetooth_conf_src = $script_dir_path + "/pulseaudio-bluetooth.conf"
let pulseaudio_bluetooth_conf_dest = $rootfs_dir + "/etc/dbus-1/system.d/pulseaudio-bluetooth.conf"

let system_pa_src = $script_dir_path + "/system.pa"
let system_pa_dest = $rootfs_dir + "/etc/pulse/system.pa"



log_debug $"Copying ($bluetooth_hci_enable_service_src) to ($bluetooth_hci_enable_service_dest)"
SUDO cp $bluetooth_hci_enable_service_src $bluetooth_hci_enable_service_dest 

log_debug $"Copying ($pulseaudio_bluetooth_conf_src) to ($pulseaudio_bluetooth_conf_dest)"
SUDO cp $pulseaudio_bluetooth_conf_src $pulseaudio_bluetooth_conf_dest


log_debug $"Copying ($system_pa_src) to ($system_pa_dest)"
SUDO cp $system_pa_src $system_pa_dest

}