#!/usr/bin/env nu

use modules/logger.nu *


# Global variables
const UBOOT_REPO = "https://github.com/chiragp-mecha/u-boot"
const IMX_ATF_REPO = "https://github.com/nxp-imx/imx-atf"
const IMX_MKIMAGE_REPO = "https://github.com/nxp-imx/imx-mkimage"
const FIRMWARE_URL = "https://www.nxp.com/lgfiles/NMG/MAD/YOCTO/firmware-imx-8.20.bin"
const ARCH = "arm64"
const CROSS_COMPILE = "/usr/bin/aarch64-linux-gnu-"

# Entry point
def main [uboot_dir:string, build_dir:string] {
    log_info "Starting build script"

    let u_boot_dir = $uboot_dir
    let work_dir = $build_dir +  "/work";
    let deploy_dir = $build_dir + "/deploy";
    
    log_info "Checking for necessary directories"
    create_dir_if_not_exist $work_dir
    create_dir_if_not_exist $deploy_dir
    create_dir_if_not_exist $u_boot_dir

    load-env {
        ARCH: $ARCH
        CROSS_COMPILE: $CROSS_COMPILE
        WORK_DIR: $work_dir
        DEPLOY_DIR: $deploy_dir
        UBOOT_DIR: $u_boot_dir
    }


    log_info "Building U-Boot"
    build_uboot $u_boot_dir

    # building imx trusted firmware
    build_imx_trusted_firmware $work_dir

    # download and extract firmware
    download_firmware $work_dir

    # building imx mkimage
    build_imx_mkimage $work_dir

    # copy necessary files
    copy_files

    # build final image
    build_image

    # collect artifacts
    collect_artifacts
  


}

# fetch source code
def fetch_source_code [repo_url: string, dest_dir: string] {
    log_info $"Checking if directory ($dest_dir) exists"

    if ( $dest_dir | path exists) {
        log_warn $"Directory ($dest_dir) already exists and is not empty"
        log_info "Skipping clone"
        return
    }

    log_info $"Cloning repository ($repo_url) to ($dest_dir)"
    git clone $repo_url $dest_dir
}

# Check if directory exists
def create_dir_if_not_exist [dir: string] {
    let check_if_path_exists: bool =   ($dir | path exists)
    if $check_if_path_exists {
        log_info $"Directory ($dir) already exists"
    } else {
        log_info $"Creating directory ($dir)"
        mkdir $dir
    }
   
}

def build_uboot [uboot_dir:string] {

    log_info "Fetching U-Boot source code"
    fetch_source_code $UBOOT_REPO ($uboot_dir)

    log_info "Building U-Boot"
    cd ($uboot_dir)
    make clean
    make mecha_comet_defconfig
    make -j (nproc)

    log_info "U-Boot build completed successfully"

    cd $uboot_dir


}

def build_imx_trusted_firmware [work_dir:string] {
    log_info "Building IMX Trusted Firmware"

    log_debug $"Fetching IMX Trusted Firmware source code from ($IMX_ATF_REPO) to ($work_dir)"

    fetch_source_code $IMX_ATF_REPO ($work_dir + "/imx-atf")
    cd ($work_dir + "/imx-atf")

    git checkout 99195a23d3aef485fb8f10939583b1bdef18881c
    make PLAT=imx8mm bl31
    log_info "IMX Trusted Firmware build completed successfully"

    cd $work_dir

}

def download_firmware [work_dir:string] {
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

def build_imx_mkimage [work_dir:string] {
    log_info "Building IMX MKIMAGE"

    let mkimage_dir = ($work_dir + "/imx-mkimage")
    fetch_source_code $IMX_MKIMAGE_REPO ($mkimage_dir)
    cd ($mkimage_dir)
    git checkout d489494622585a47b4be88988595b0e4f9598f39
    log_info "IMX MKIMAGE build completed successfully"
    cd $work_dir
}


def copy_files [] {
    echo "Copying necessary files to IMX MKIMAGE directory"
    let uboot_dir = $env.UBOOT_DIR
    let work_dir = $env.WORK_DIR

    # log working directory and uboot directory
    log_info $"U-Boot directory: ($uboot_dir)"
    log_info $"Work directory: ($work_dir)"

    let mkimage_dir = ($work_dir | path join "imx-mkimage" "iMX8M")
    cp ($uboot_dir | path join "spl" "u-boot-spl.bin") $mkimage_dir
    cp ($uboot_dir | path join "u-boot-nodtb.bin") $mkimage_dir
    cp ($uboot_dir | path join "arch" "arm" "dts" "mecha-comet.dtb") $mkimage_dir
    cp ($uboot_dir | path join "tools" "mkimage") ($mkimage_dir | path join "mkimage_uboot")
    cp ($work_dir | path join "imx-atf" "build" "imx8mm" "release" "bl31.bin") $mkimage_dir


    let synopsys_dir = ($work_dir | path join "firmware-imx" "firmware-imx-8.20" "firmware" "ddr" "synopsys")
    log_info ($"Synopsys directory: ($synopsys_dir)")
    let pattern = ($synopsys_dir | path join "lpddr4_pmu_train_*")
    glob $pattern | each { |file| cp $file $mkimage_dir }

    cp ($mkimage_dir | path join "mecha-comet.dtb") ($mkimage_dir | path join "mecha-comet-evk.dtb")
}



def build_image [] {
    log_info "Building final image"
    let work_dir = $env.WORK_DIR
    cd ($work_dir | path join "imx-mkimage" )
    make SOC=iMX8MM PLAT=mecha-comet flash_evk
    log_info "Image build completed successfully"
}

def collect_artifacts [] {
    log_info "Collecting artifacts"
    let deploy_dir = $env.DEPLOY_DIR
    let work_dir = $env.WORK_DIR

    let mkimage_dir = ($work_dir | path join "imx-mkimage" "iMX8M" "flash.bin")
    cp $mkimage_dir $deploy_dir
}