#!/usr/bin/env nu
use logger.nu
use os-config.nu *

const HOST_INSTALLATION_CONF = "conf-packages/host.yml"
const TARGET_INSTALLATION_CONF = "conf-packages/target.yml"

alias CHROOT = sudo chroot

export def install_target_packages [] {
    log_info "Installing target packages:"

    let rootfs_dir = $env.ROOTFS_DIR
    alias CHROOT = sudo chroot $rootfs_dir

    # Clean DNF cache and update metadata
    CHROOT dnf clean all
    CHROOT dnf -y makecache

    # Configure keyboard layout (if you have a function for this)
    keyboard_config

    let package_groups = open $TARGET_INSTALLATION_CONF | get package_groups

    for pkg_group in $package_groups {
        log_debug $"Processing package group: ($pkg_group.packages)"

        if ($pkg_group.packages | length) == 0 {
            log_debug "No packages found in this group."
            continue
        }

        for pkg in $pkg_group.packages {
            try {
                log_debug $"Attempting to install package: ($pkg)"
                CHROOT dnf -y --setopt=install_weak_deps=False install $pkg
            } catch {|err|
                log_error $"Failed to install package ($pkg): ($err)"
                continue
            }
        }
    }
}


export def install_kernel_packages_from_source [] {
    log_info "Installing kernel packages:"

    let rootfs_dir = $env.ROOTFS_DIR
    alias CHROOT = sudo chroot $rootfs_dir

    let build_conf_path = $env.BUILD_CONF_PATH

    #get kernel packages from the YAML configuration 
    let script_dir_path =  (open $build_conf_path | get include-path)

    let kernel_packages_path = $script_dir_path+ "/firmware"

    # this folder contains all rpm packages for the kernel we want to install
    if (ls $kernel_packages_path | is-empty) {
        log_info "No kernel packages found in: ($kernel_packages_path)"
        return
    }

    for pkg in (ls $kernel_packages_path) {
        try {
            log_debug $"Attempting to install kernel package: ($pkg)"
            CHROOT dnf -y --setopt=install_weak_deps=False install $pkg
        } catch {|err|
            log_error $"Failed to install kernel package ($pkg): ($err)"
            continue
        }
    }

    log_info "Kernel packages installed successfully."

    # we need to list content of /boot directory to check if kernel is installed
    let boot_dir = $rootfs_dir + "/boot"
    if (ls $boot_dir | is-empty) {
        log_error "Boot directory is empty, kernel installation might have failed."
        return
    }
    log_info "Boot directory contains: ($boot_dir)"
    log_info "Kernel packages installed successfully."
}


export def add_debian_mechanix_source [] {
    let rootfs_dir = $env.ROOTFS_DIR
    alias CHROOT = sudo chroot $rootfs_dir

    let sources_list_path = "/etc/apt/sources.list"

    # Get the package source from the YAML configuration
    let build_conf_path = $env.BUILD_CONF_PATH
    let deb_package_sources = open $build_conf_path | get apt | get sources

    log_info "Adding Mechanix package sources to sources.list"

    # Iterate through each source and add it to sources.list
    $deb_package_sources | each { |source|
        let source_line = $"deb [trusted=yes] ($source)"
        log_debug $"Adding source: ($source_line)"
        
        sudo chroot $rootfs_dir bash -c $"echo '($source_line)' >> ($sources_list_path)"

        if $env.LAST_EXIT_CODE != 0 {
            log_error $"Failed to add source: ($source_line)"
            return
        }
    }

    log_info "Successfully added all Mechanix package sources"

    # Update package lists
    log_info "Updating package lists"
    CHROOT apt-get update

    if $env.LAST_EXIT_CODE == 0 {
        log_info "Successfully updated package lists"
    } else {
        log_error "Failed to update package lists"
    }
}