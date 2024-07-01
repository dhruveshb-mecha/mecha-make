#!/usr/bin/env nu

use logger.nu

alias SUDO = sudo

# Function to check for and install necessary dependencies
export def check_and_install_dependencies [] {
    log_info "Checking for necessary dependencies"
    let dependencies = ["gcc-aarch64-linux-gnu" "libncurses-dev" "flex" "bison" "openssl" "libssl-dev" "dkms" "libelf-dev" "libudev-dev" "libpci-dev" "libiberty-dev" "autoconf" "bc" "git" "wireshark"]
    let installed_packages = (apt list --installed | lines)

        # Create an empty array for missing dependencies
        let missing_packages = []

        # Check each dependency
        for dep in $dependencies {
            let matching_packages = ($installed_packages | where {|pkg| echo $pkg | str contains $dep})
            if ($matching_packages | length) == 0 {
                let missing_packages = ($missing_packages | append $dep)
            }
        }
    
        # Check the length of missing_packages
        let missing_packages_length = ($missing_packages | length)


    # if ($missing_packages | length) > 0 {
    #     print $"Installing missing dependencies: ($missing_packages)"
    #     SUDO apt-get update
    #     SUDO apt-get install -y $missing_packages
    # } else {
    #     log_debug "All necessary dependencies are already installed."
    # }
}