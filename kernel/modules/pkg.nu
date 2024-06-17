#!/usr/bin/env nu

use logger.nu

alias SUDO = sudo

# Function to check for and install necessary dependencies
export def check_and_install_dependencies [] {
    log_info "Checking for necessary dependencies"
    let dependencies = ["gcc-aarch64-linux-gnu" "libncurses-dev" "flex" "bison" "openssl" "libssl-dev" "dkms" "libelf-dev" "libudev-dev" "libpci-dev" "libiberty-dev" "autoconf" "bc" "git"]
    let installed_packages = (apt list --installed | get name)
    let missing_dependencies = (
        $dependencies
        | filter
            { |dep| !($installed_packages | any? { |pkg| $pkg == $dep }) }
    )

    if ($missing_dependencies | length) > 0 {
        print $"Installing missing dependencies: ($missing_dependencies)"
        SUDO apt-get update
        SUDO apt-get install -y $missing_dependencies
    } else {
        log_debug "All necessary dependencies are already installed."
    }
}