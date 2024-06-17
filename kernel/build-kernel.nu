#!/usr/bin/env nu

use modules/logger.nu *
# Function to exit script on error and print a failure message
def exit_on_error [err: string] {
    log_error $"An error occurred: ($err). Exiting..."
    exit 1
}

# Check if arguments are provided
if ($env.args | length) != 1 {
    log_info $"Usage: ($env.nu.path) <BUILD_DIR>"
    exit 1
}

# Destructure the argument
let build_dir = ($env.args | get 0)
let work_dir = $"($build_dir)/work"
let deploy_dir = $"($build_dir)/deploy"

# Variables
let arch = "arm64"
let cross_compile = "/usr/bin/aarch64-linux-gnu-"
let kernel_repo = "https://github.com/chiragp-mecha/linux-imx.git"
let config_file = "arch/arm64/configs/mecha_comet_m_gen1.config"

# Function to check for and install necessary dependencies
def check_and_install_dependencies [] {
    log_info "Checking for necessary dependencies"
    let dependencies = ["gcc-aarch64-linux-gnu" "libncurses-dev" "flex" "bison" "openssl" "libssl-dev" "dkms" "libelf-dev" "libudev-dev" "libpci-dev" "libiberty-dev" "autoconf" "bc" "git"]
    let installed_packages = (apt list --installed | get name)
    let missing_dependencies = (
        $dependencies
        | filter
            { |dep| !($installed_packages | any? { |pkg| $pkg == $dep }) }
    )

    if ($missing_dependencies | length) > 0 {
        log_debug $"Installing missing dependencies: ($missing_dependencies)"
        sudo apt-get update
        sudo apt-get install -y $missing_dependencies
    } else {
        log_debug "All necessary dependencies are already installed."
    }
}

# Clone repository function
def fetch_source_code [repo_url: string, dest_dir: string] {
    if !(mkdir $dest_dir) {
        git clone $repo_url $dest_dir
    } else {
        log_debug $"Directory ($dest_dir) already exists. Skipping clone."
    }
}

# Build Kernel
def build_kernel [] {
    log_info "Building Kernel"
    let linux_imx_dir = $work_dir + "/linux-imx"
    fetch_source_code $kernel_repo $linux_imx_dir
    with env {
        ARCH = $arch
        CROSS_COMPILE = $cross_compile
        DEBIAN_FRONTEND = "noninteractive"
    } {
        cd $work_dir/linux-imx
        cp $config_file .config

        make clean
        yes "" | make -j (nproc)
        make modules
        cd $work_dir
    }
}

# Collect artifact
def collect_artifact [] {
    log_info "Collecting artifact"
    mkdir  $deploy_dir

    let artifact_path_1 = $work_dir + "/linux-imx/arch/$arch/boot/Image"
    let artifact_path_2 = $work_dir + "/linux-imx/arch/$arch/boot/dts/freescale/imx8mm-mecha-comet-m-gen1*"
    
    let deploy_dir = $"$deploy_dir/kernel"

    cp $artifact_path_1 $deploy_dir
    cp $artifact_path_2 $deploy_dir
}

# Main script execution
log_info "Starting kernel build script"
check_and_install_dependencies
build_kernel
collect_artifact
log_info "Kernel build script completed successfully"