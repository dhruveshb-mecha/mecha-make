#!/usr/bin/env nu

use logger.nu
use fetch-source.nu

export def build_imx_trusted_firmware [work_dir:string] {
    log_info "Building IMX Trusted Firmware"
    let imx_atf_dir = ($work_dir + "/imx-atf") | path expand
    mkdir $imx_atf_dir

    let manifest = "../manifest/mecha-comet-m-gen1.yml" | path expand
    let IMX_ATF_REPO = open $manifest | get imx-atf | get url

    log_debug $"Fetching IMX Trusted Firmware source code from ($IMX_ATF_REPO) to ($imx_atf_dir)"
    curl -L $IMX_ATF_REPO | tar -xz -C $imx_atf_dir --strip-components=1
    cd $imx_atf_dir

    make PLAT=imx8mm bl31

    log_info "IMX Trusted Firmware build completed successfully"
    cd $work_dir
}

export def download_firmware [work_dir:string] {
    log_info "Downloading and extracting firmware"

    # grab manifest file before entering the firmware directory
    let manifest = "../manifest/mecha-comet-m-gen1.yml" | path expand
    log_debug $"Fetching firmware URL from ($manifest)"
    let FIRMWARE_URL = open $manifest | get trusted-firmware | get url

    let firmware_dir = ($work_dir + "/firmware-imx")
    create_dir_if_not_exist $firmware_dir
    cd $firmware_dir

    let firmware_file = ($firmware_dir + "/firmware-imx-8.20.bin")
    if (not ($firmware_file | path exists)) {
        curl -LO $FIRMWARE_URL
        chmod a+x firmware-imx-8.20.bin
        yes | ./firmware-imx-8.20.bin | more +700
    } else {
        log_info "Firmware already downloaded. Skipping."
    }

    cd $work_dir
}

export def build_imx_mkimage [work_dir:string] {
    log_info "Building IMX MKIMAGE"
    let mkimage_dir = ($work_dir + "/imx-mkimage") | path expand
    
    if ($mkimage_dir | path exists) {
        log_info $"IMX MKIMAGE directory already exists at ($mkimage_dir). Skipping clone and build."
        return
    }

    mkdir $mkimage_dir

    let manifest = "../manifest/mecha-comet-m-gen1.yml" | path expand
    let IMX_MKIMAGE_REPO = open $manifest | get imx-mkimage | get url
    let IMX_MKIMAGE_COMMIT = open $manifest | get imx-mkimage | get commit-id

    log_debug $"Fetching IMX MKIMAGE source code from ($IMX_MKIMAGE_REPO) to ($mkimage_dir)"

    git clone $IMX_MKIMAGE_REPO $mkimage_dir
    cd $mkimage_dir
    git checkout $IMX_MKIMAGE_COMMIT
    log_info "IMX MKIMAGE build completed successfully"
    cd $work_dir
}
