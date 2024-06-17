#!/usr/bin/env nu

use logger.nu
use fetch-source.nu


const IMX_ATF_REPO = "https://github.com/nxp-imx/imx-atf"
const IMX_MKIMAGE_REPO = "https://github.com/nxp-imx/imx-mkimage"
const FIRMWARE_URL = "https://www.nxp.com/lgfiles/NMG/MAD/YOCTO/firmware-imx-8.20.bin"


export def build_imx_trusted_firmware [work_dir:string] {
    log_info "Building IMX Trusted Firmware"

    log_debug $"Fetching IMX Trusted Firmware source code from ($IMX_ATF_REPO) to ($work_dir)"

    fetch_source $IMX_ATF_REPO ($work_dir + "/imx-atf")
    cd ($work_dir + "/imx-atf")

    git checkout 99195a23d3aef485fb8f10939583b1bdef18881c
    make PLAT=imx8mm bl31
    log_info "IMX Trusted Firmware build completed successfully"

    cd $work_dir

}

export def download_firmware [work_dir:string] {
    log_info "Downloading and extracting firmware"
    let firmware_dir = ($work_dir + "/firmware-imx")
    create_dir_if_not_exist $firmware_dir
    cd $firmware_dir

    let firmware_file = ($firmware_dir + "/firmware-imx-8.20.bin")
    if (not ($firmware_file | path exists)) {
        wget $FIRMWARE_URL
        chmod a+x firmware-imx-8.20.bin
        yes | ./firmware-imx-8.20.bin | more +700
    } else {
        log_info "Firmware already downloaded. Skipping."
    }

    cd $work_dir
}

export def build_imx_mkimage [work_dir:string] {
    log_info "Building IMX MKIMAGE"

    let mkimage_dir = ($work_dir + "/imx-mkimage")
    fetch_source $IMX_MKIMAGE_REPO ($mkimage_dir)
    cd ($mkimage_dir)
    git checkout d489494622585a47b4be88988595b0e4f9598f39
    log_info "IMX MKIMAGE build completed successfully"
    cd $work_dir
}