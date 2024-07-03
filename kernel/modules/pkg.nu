#!/usr/bin/env nu

use logger.nu

alias SUDO = sudo

# Function to check for and install necessary dependencies
export def check_and_install_dependencies [] {
    log_info "Checking for necessary dependencies"
    let dependencies = ["gcc-aarch64-linux-gnu" "libncurses-dev" "flex" "bison" "openssl" "libssl-dev" "dkms" "libelf-dev" "libudev-dev" "libpci-dev" "libiberty-dev" "autoconf" "bc" "git" ]

    # Find missing dependencies
    let missing_deps = (find_missing_dependencies $dependencies)
    log_debug $"Missing dependencies: ($missing_deps)"

    # Display the results
    if ($missing_deps | is-empty) {
         log_debug "All required dependencies are installed."
    } else {
           log_info "Installing missing dependencies..."
            for dep in $missing_deps {
                SUDO apt install $dep
            }
    }
}


def get_installed_programs [] {
    ^apt list --installed
    | lines
    | skip 1  # Skip the header line
    | parse "{package}/{version} {arch} {status}"
    | where status =~ "installed"
    | get package
}

def find_missing_dependencies [required_deps: list] {
    let installed_programs = (get_installed_programs)
    $required_deps | where { |dep| $dep not-in $installed_programs }
}