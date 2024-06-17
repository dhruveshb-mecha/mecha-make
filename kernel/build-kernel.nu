#!/usr/bin/env nu

use modules/logger.nu *
use modules/pkg.nu *
use modules/utils.nu *


# Variables
let arch = "arm64"
let cross_compile = "/usr/bin/aarch64-linux-gnu-"
let kernel_repo = "https://github.com/chiragp-mecha/linux-imx.git"
let config_file = "arch/arm64/configs/mecha_comet_m_gen1.config"
let debian_frontend = "noninteractive"


# Entry point
def main [build_dir: string] {

    log_info "Starting kernel build script"

  let work_dir = $build_dir + "/work"
  let deploy_dir = $build_dir + "/deploy"

    ## Create directories
    create_dir $work_dir
    create_dir $deploy_dir

  ## Set environment variables
  load-env {
    BUILD_DIR: $build_dir,
    WORK_DIR: $work_dir,
    DEPLOY_DIR: $deploy_dir,
    ARCH: $arch,
    CROSS_COMPILE: $cross_compile,
    DEBIAN_FRONTEND : $debian_frontend
  }
    check_and_install_dependencies
    build_kernel
    collect_artifact
    log_info "Kernel build script completed successfully"
}


def create_dir [dir: string] {
    if (path_exists $dir) {
        log_info "Directory ($dir) already exists"
    } else {
        mkdir $dir
        log_info "Directory ($dir) created successfully"
    }
}


# Build Kernel
def build_kernel [] {
    log_info "Building Kernel"
    let work_dir = $env.WORK_DIR
    let linux_imx_dir = $work_dir + "/linux-imx"

    fetch_source $kernel_repo $linux_imx_dir

    cd $linux_imx_dir
    cp $config_file .config

    make clean
    yes "" | make -j (nproc)
    make modules
    cd $work_dir
    
}

# Collect artifact
def collect_artifact [] {
    log_info "Collecting artifact"
    let deploy_dir = $env.DEPLOY_DIR
    let work_dir = $env.WORK_DIR

    let artifact_path_1 = $work_dir + "/linux-imx/arch/$arch/boot/Image"
    let artifact_path_2 = $work_dir + "/linux-imx/arch/$arch/boot/dts/freescale/imx8mm-mecha-comet-m-gen1*"
  
    cp $artifact_path_1 $deploy_dir
    cp $artifact_path_2 $deploy_dir
    log_debug "Artifact collected successfully"
}
