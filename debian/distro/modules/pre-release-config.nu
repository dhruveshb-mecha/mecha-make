#!/usr/bin/env nu

use logger.nu

export def update_pre_release_assets [] {
    log_info "Updating Mecha Comet pre-release assets in target rootfs"

    # Rootfs target 
    let rootfs_dir = $env.ROOTFS_DIR
    log_debug $"Target rootfs directory: ($rootfs_dir)"

    # Temp dir
    let tmp_dir = "/tmp/mecha-assets"
    sudo mkdir -p $tmp_dir

    # Download zip file
    let url = "https://pub-a2f44c787cec4290833312e57fd59522.r2.dev/mecha-comet-pre-release-assets.zip"
    log_debug $"Downloading pre-release assets from ($url)"
    curl -o ($tmp_dir + "/mecha-comet-pre-release-assets.zip") $url

    # Extract zip
    log_debug "Extracting assets..."
    sudo unzip -o ($tmp_dir + "/mecha-comet-pre-release-assets.zip") -d $tmp_dir

    let extracted_dir = $tmp_dir + "/mecha-comet-pre-release-assets"

    # Copy boot Image
    sudo mkdir -p ($rootfs_dir + "/boot")
    sudo cp ($extracted_dir + "/Image") ($rootfs_dir + "/boot/Image")
    log_debug "Boot Image updated in target rootfs."

    # Copy kernel modules (entire folder)
    sudo mkdir -p ($rootfs_dir + "/lib/modules")
    sudo cp -r ($extracted_dir + "/6.12.20-gdfaf2136deb2-dirty") ($rootfs_dir + "/lib/modules/")
    log_debug "Kernel modules updated in target rootfs."

    # Copy WiFi firmware (inner nxp folder only)
    sudo mkdir -p ($rootfs_dir + "/lib/firmware")
    sudo cp -r ($extracted_dir + "/nxp-wifi-firmware/nxp") ($rootfs_dir + "/lib/firmware/nxp")
    log_debug "WiFi firmware updated in target rootfs."

    # Cleanup
    sudo rm -r $tmp_dir
    log_info "Pre-release assets installation complete."
}


