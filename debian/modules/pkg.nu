#!/usr/bin/env nu
use logger.nu

const PACKAGE_CONF_PATH = "conf-packages/host.yml"
const TARGET_PACKAGE_CONF_PATH = "conf-packages/target.yml"

alias CHROOT = sudo chroot

def install_package [name: string, url: string, sha] {
    let tmp_dir = $env.TMP_DIR
    let pkg_path = $"($tmp_dir)/($name)-($sha).deb"

    log_debug $"Downloading ($name) ..."
    wget -q $url -P $tmp_dir -O $pkg_path

    log_debug $"Installing ($name) ..."
    SUDO dpkg -i $pkg_path

    log_debug $"Package ($name) is installed"

    # TODO: Verify SHA
    # TODO: avoid redownload, if file exists + SHA matched
}

export def install_host_packages [] {
    log_info "Installing host packages:"

    # add the package source
    

    # let packages = open $PACKAGE_CONF_PATH;
    log_debug $"Number of packages found: (open $PACKAGE_CONF_PATH | get packages | length)"

    let _  = open $PACKAGE_CONF_PATH | get packages | each {|pkg| 
        install_package $pkg.name $pkg.url $pkg.sha
    }
}

export def install_target_packages [] {

    log_info "Installing target packages:"
    

let rootfs_dir = $env.ROOTFS_DIR
alias CHROOT = sudo chroot $rootfs_dir

# clean up and update
CHROOT apt-get clean
CHROOT apt-get update


let package_groups = open $TARGET_PACKAGE_CONF_PATH | get package_groups

for pkg_group in $package_groups {
    log_debug $"Installing package group: ($pkg_group.packages)"

    # Check if the length of the list of packages is 0
    if ($pkg_group.packages | length) == 0 {
        log_debug "No packages found in this group."
    } else {
        # Iterate over each package within the group
        for pkg in $pkg_group.packages {
            log_debug $"Installing package: ($pkg)"
            # Install the package
            CHROOT apt-get -y --allow-change-held-packages install $pkg
        }
    }
}

  

    # CHROOT apt-get clean
    # CHROOT apt-get update

    # CHROOT apt-get -y --force-yes install dbus nano openssh-server sudo bash-completion dosfstools
    # CHROOT apt-get -y --force-yes install bluez hostapd file ethtool network-manager
    # CHROOT apt-get -y --force-yes install python3
    # CHROOT apt-get -y --force-yes install systemd-timesyncd
    # CHROOT apt-get -y --force-yes install xwayland
    # CHROOT apt-get -y --force-yes install xorg mesa-utils sway weston
    # CHROOT apt-get -y --force-yes install net-tools
    # CHROOT apt-get -y --force-yes install greetd
    # CHROOT apt-get -y --force-yes install alsa-tools alsa-utils libasound2 libasound2-plugins

    # pulseaudio
    # CHROOT apt-get -y --force-yes install pulseaudio mpg123 pulseaudio-module-bluetooth

    # pipewire
    # CHROOT apt-get -y --force-yes install pipewire pipewire-pulse pipewire-alsa

    # CHROOT apt-get -y --force-yes install locales-all
}
