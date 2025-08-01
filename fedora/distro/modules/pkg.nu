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
    #keyboard_config

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


export def install_kernel_packages_from_repo [] {
    log_info "Installing kernel packages from configured RPM repo"

    let rootfs_dir = $env.ROOTFS_DIR
    alias CHROOT = sudo chroot $rootfs_dir

    # Define the exact package names you want to install
    let kernel_packages = [
        "linux-headers-6.6.36+mecha+-0:6.6.36_g98f2850cc265-2.arm64"
        "linux-image-6.6.36+mecha+-0:6.6.36_g98f2850cc265-2.arm64"
    ]

    for pkg in $kernel_packages {
        try {
            log_debug $"Installing kernel package from repo: ($pkg)"
            CHROOT dnf -y --setopt=install_weak_deps=False install $"($pkg)"
        } catch {|err|
            log_error $"Failed to install ($pkg): ($err)"
            return
        }
    }

    log_info "Kernel packages installed successfully from repo."

    # Validate /boot contents to confirm installation
    let boot_dir = $rootfs_dir + "/boot"
    if (ls $boot_dir | is-empty) {
        log_error "Boot directory is empty, kernel installation might have failed."
        return
    }

    log_info "Boot directory contains:"
    ls $boot_dir | each {|entry| log_info $"  ($entry.name)" }

    log_info "Kernel install validation complete."
}



export def add_fedora_mechanix_repo [] {
    let rootfs_dir = $env.ROOTFS_DIR
    alias CHROOT = sudo chroot $rootfs_dir

    let repo_file_path = "/etc/yum.repos.d/comet-pulp.repo"
    let repo_contents = '''
[comet-pulp]
name=Comet Pulp RPM Repository
baseurl=http://167.235.132.100:8080/pulp/content/comet-rpm/
enabled=1
gpgcheck=0
'''

    log_info "Adding Mechanix RPM repository to yum.repos.d"

    # Use tee inside chroot to write the repo file
    echo $repo_contents 
    | CHROOT tee $repo_file_path 
    | complete > /dev/null

    if $env.LAST_EXIT_CODE != 0 {
        log_error "Failed to add RPM repository"
        return
    }

    log_info "Successfully added RPM repository"

    # Clean and update repo metadata
    log_info "Cleaning and updating repository metadata"
    CHROOT dnf clean all
    CHROOT dnf makecache

    if $env.LAST_EXIT_CODE == 0 {
        log_info "Successfully updated repository metadata"
    } else {
        log_error "Failed to update repository metadata"
    }
}