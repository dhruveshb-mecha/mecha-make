#!/usr/bin/env nu

use logger.nu

alias SUDO = sudo

const HOST_PACKAGES = "./conf-packages/host.yml"

# Function to check for and install necessary dependencies
export def check_and_install_dependencies [] {
    log_info "Checking for necessary dependencies"

    let required_dependencies = open $HOST_PACKAGES | get packages
    log_debug $"Required dependencies: ($required_dependencies)"

    let missing_deps = (find_missing_dependencies $required_dependencies)
    log_debug $"Missing dependencies: ($missing_deps)"

    if ($missing_deps | is-empty) {
        log_debug "All required dependencies are installed."
    } else {
        log_info "Installing missing dependencies..."
        for dep in $missing_deps {
            SUDO dnf install -y $dep
        }
    }
}

# Get list of installed packages (RPM systems)
def get_installed_programs [] {
    ^rpm -qa | lines
}

# Compare required vs installed
def find_missing_dependencies [required_deps: list] {
    let installed_programs = (get_installed_programs)
    $required_deps | where { |dep| not ($installed_programs | any { |pkg| $pkg =~ $dep }) }
}
