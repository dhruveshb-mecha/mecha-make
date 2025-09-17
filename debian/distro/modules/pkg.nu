#!/usr/bin/env nu
use logger.nu
use os-config.nu *

const HOST_INSTALLATION_CONF = "conf-packages/host.yml"
const TARGET_INSTALLATION_CONF = "conf-packages/target.yml"

alias CHROOT = sudo chroot

def install_package [name: string, url: string, sha] {
    let tmp_dir = $env.TMP_DIR
    let pkg_path = $"($tmp_dir)/($name)-($sha).deb"

    log_debug $"Downloading ($name) ..."
    wget -q $url -P $tmp_dir -O $pkg_path

    log_debug $"Installing ($name) ..."
    SUDO dpkg -i $pkg_path

    log_debug $"Package ($name) is installed"
}

export def install_host_packages [] {
    log_info "Installing host packages:"


    log_debug $"Number of packages found: (open $HOST_INSTALLATION_CONF | get packages | length)"

    open $HOST_INSTALLATION_CONF | get packages | each {|pkg| 
        # Catch and handle individual package installation failures
        try {
            install_package $pkg.name $pkg.url $pkg.sha
        } catch {|err| 
            log_error $"Failed to install package ($pkg.name): ($err)"
         
        }
    }

}

export def install_target_packages [] {
    log_info "Installing target packages:"
    
    let rootfs_dir = $env.ROOTFS_DIR
    alias CHROOT = sudo chroot $rootfs_dir

    # Clean old cache and update package lists
    CHROOT apt-get clean
    log_info "Updating package lists..."
    
    # Retry update up to 3 times if it fails or is slow
    let max_retries = 3
    let retry = 0
    while ($retry < $max_retries) {
        log_debug $"Attempt ($retry + 1) for apt-get update"
        CHROOT apt-get update -o Acquire::Retries=3
        if $env.LAST_EXIT_CODE == 0 {
            log_info "apt-get update completed successfully"
            break
        } else {
            log_error $"apt-get update failed on attempt ($retry + 1)"
            sleep 2
            retry += 1
        }
    }

    if $retry == $max_retries {
        log_error "apt-get update failed after 3 attempts, aborting package install"
        return
    }

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
                # Install package after update is guaranteed complete
                CHROOT apt-get -y --allow-change-held-packages install $pkg
            } catch {|err| 
                log_error $"Failed to install package ($pkg): ($err)"
                continue
            }
        }
    }
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