


#!/usr/bin/env nu

use logger.nu

alias SUDO = sudo

export def configure_sys_files [] {

  log_info "Configuring system files:"
  let rootfs_dir = $env.ROOTFS_DIR
  let build_conf_path = $env.BUILD_CONF_PATH
  

  let script_dir_path =  (open $build_conf_path | get include-path)

  let domain_contet = '127.0.0.1       localhost.localdomain           comet-m'
  let temp_file = "/tmp/domain-content"

  echo $domain_contet | save --force $temp_file

  let hosts_dest = $rootfs_dir + "/etc/hosts"

  SUDO mv $temp_file $hosts_dest

  let hostname_content = "comet-m"
  let temp_file = "/tmp/hostname-content"

  echo $hostname_content | save --force $temp_file

  let hostname_dest = $rootfs_dir + "/etc/hostname"

  SUDO mv $temp_file $hostname_dest

  let issue_content = "Welcome Mechanix V1.1 \n"
  let temp_file = "/tmp/issue-content"

  echo $issue_content | save --force $temp_file

  let issue_dest = $rootfs_dir + "/etc/issue"

  SUDO mv $temp_file $issue_dest

  let motd_content = "---------Mecha-Comet-M-Gen1---------"
  let temp_file = "/tmp/motd-content"

  echo $motd_content | save --force $temp_file

  let motd_dest = $rootfs_dir + "/etc/motd"

  SUDO mv $temp_file $motd_dest

  let fstab_src = $script_dir_path + "/fstab"
  let fstab_dest = $rootfs_dir + "/etc/fstab"

  SUDO cp $fstab_src $fstab_dest

  let logind_conf_content = "HandlePowerKey=ignore"
  let logind_conf_dest = $rootfs_dir + "/etc/systemd/logind.conf"
  # Check if the content already exists, and if not, append it
  SUDO sh -c $"grep -qxF '($logind_conf_content)' ($logind_conf_dest) || echo '($logind_conf_content)' >> ($logind_conf_dest)"

  log_debug "Configuring system files completed successfully."


}

export def configure_greeter [] {
  log_info "Configuring greeter:"
  let rootfs_dir = $env.ROOTFS_DIR

  alias CHROOT = sudo chroot $rootfs_dir

  # Create greeter user for greetd, enable greetd-service and disable getty-service
  # log_debug "Creating greeter user for greetd, enabling greetd-service and disabling getty-service"
  # CHROOT useradd -M greeter
  # CHROOT usermod -aG video greeter
  # CHROOT usermod -aG render greeter
  # CHROOT usermod -d /usr/greeter greeter

  let config_append = "\n" + ("# Performs auto login for default user

[initial_session]
command = \"labwc\"
user = \"mecha\"" | str trim) + "\n"

  let greetd_config_path = $rootfs_dir + "/etc/greetd/config.toml"
  echo $config_append | sudo tee -a $greetd_config_path

  CHROOT systemctl disable getty@tty1.service
  CHROOT systemctl enable greetd.service

}



export def configure_ssh [] {
  log_info "Configuring ssh:"
  let rootfs_dir = $env.ROOTFS_DIR
  let build_conf_path = $env.BUILD_CONF_PATH

  let script_dir_path =  (open $build_conf_path | get include-path)
  alias CHROOT = sudo chroot $rootfs_dir

  #CHROOT rm /etc/ssh/ssh_host_*
  CHROOT mkdir -p /usr/libexec/openssh

  let sshd_check_keys_src = $script_dir_path + "/sshd-key-gen/sshd_check_keys"
  let sshd_check_keys_dest = $rootfs_dir + "/usr/libexec/openssh"

  log_debug $"Copying ($sshd_check_keys_src) to ($sshd_check_keys_dest)"
  SUDO cp $sshd_check_keys_src $sshd_check_keys_dest
  SUDO chmod 744 $"($rootfs_dir)/usr/libexec/openssh/sshd_check_keys"

  let sshdgenkeys_service_src = $script_dir_path + "/sshd-key-gen/sshdgenkeys.service"
  let sshdgenkeys_service_dest = $rootfs_dir + "/lib/systemd/system"

  log_debug $"Copying ($sshdgenkeys_service_src) to ($sshdgenkeys_service_dest)"
  SUDO cp $sshdgenkeys_service_src $sshdgenkeys_service_dest

  log_debug "Enabling sshdgenkeys service"
  CHROOT systemctl enable sshdgenkeys.service
  log_debug "Enabling sshdgenkeys service Successfully."

}


export def configure_udev [] {

  log_info "Configuring udev:"

  let rootfs_dir = $env.ROOTFS_DIR
  let build_conf_path = $env.BUILD_CONF_PATH

  let script_dir_path =  (open $build_conf_path | get include-path)


  let udev_rules_src = $script_dir_path + "/10-imx.rules"
  let udev_rules_dest = $rootfs_dir + "/etc/udev/rules.d/10-imx.rules"

  log_info $"Copying ($udev_rules_src) to ($udev_rules_dest)"
  SUDO cp $udev_rules_src $udev_rules_dest
}


export def enable_watchdog_timer [rootfs_dir: string] {
  ### Enable Watchdog Timer 
  log_info "Enabling Watchdog Timer:"


  let watchdog_conf_path = $rootfs_dir + "/etc/systemd/system.conf"

  let tmp_watchdog_conf = "/tmp/watchdog.conf"

  let watchdog_timer = "RuntimeWatchdogSec=30"

  echo $watchdog_timer | save --force $tmp_watchdog_conf

  SUDO mv $tmp_watchdog_conf $watchdog_conf_path

}


export def configure_mechanix_system_dbus [] {
  log_info "Configuring mechanix system dbus service:"
  let rootfs_dir = $env.ROOTFS_DIR

  let service_content = "[Unit]
Description=Mechanix Services (zbus)
After=systemd-user-sessions.service
DefaultDependencies=no

[Service]
User=root
Type=exec
ExecStart=sudo /usr/bin/mechanix_system_dbus_server -c /etc/mechanix-gui/server/system/services-config.yml
Restart=always
RestartSec=2s

[Install]
WantedBy=sysinit.target"

  let service_dir = $rootfs_dir + "/lib/systemd/system"
  let service_dest = $service_dir + "/mechanix-system-dbus.service"

  # Create directory if it doesn't exist
  if not ($service_dir | path exists) {
    log_debug $"Creating directory: ($service_dir)"
    SUDO mkdir -p $service_dir
  }

  # Write service file directly using sudo tee
  echo $service_content | sudo tee $service_dest

  # Enable the service using chroot
  alias CHROOT = sudo chroot $rootfs_dir
  CHROOT systemctl enable mechanix-system-dbus.service

  log_debug "Mechanix system dbus service configured successfully."
}
export def configure_labwc_auto_launch [] {
    log_info "Configuring labwc autostart and rc.xml:"
    let rootfs_dir = $env.ROOTFS_DIR
    
    # Define the config directory relative to rootfs
    let config_dir = $"($rootfs_dir)/home/mecha/.config/labwc"
    let autostart_file = $"($config_dir)/autostart"
    let rc_file = $"($config_dir)/rc.xml"
    
    # Create the config directory if it doesn't exist
    if not ($config_dir | path exists) {
        log_debug $"Creating directory: ($config_dir)"
        mkdir $config_dir
    }
    
    # Define the autostart content
    let autostart_content = "mechanix-launcher -s /etc/mechanix/shell/launcher/settings.yml &
mechanix_desktop_dbus_server -s /etc/mechanix-gui/server/desktop/settings.yml &
mechanix-keyboard -s /etc/mechanix/shell/keyboard/settings.yml &"

    # Define the rc.xml content
    let rc_content = '<?xml version="1.0"?>
<labwc_config>
    <windowRules>
        <windowRule identifier="*" serverDecoration="no" />
        <windowRule title="Alacritty">
            <action name="ToggleMaximize" />
        </windowRule>
        <windowRule title="Mozilla Firefox">
            <action name="ToggleMaximize" />
        </windowRule>
        <windowRule title="Nautilus">
            <action name="ToggleMaximize" />
        </windowRule>
        <windowRule title="Chromium">
            <action name="ToggleMaximize" />
        </windowRule>
        <windowRule title="Mecha Connect">
            <action name="ToggleMaximize" />
        </windowRule>
        <windowRule title="Files">
            <action name="ToggleMaximize" />
        </windowRule>
        <windowRule title="Camera">
            <action name="ToggleMaximize" />
        </windowRule>
        <windowRule title="Settings">
            <action name="ToggleMaximize" />
        </windowRule>
    </windowRules>
</labwc_config>'
    
    # Configure autostart file
    if not ($autostart_file | path exists) {
        log_debug $"Creating autostart file: ($autostart_file)"
        echo $autostart_content | save $autostart_file
        # Set proper permissions
        SUDO chmod 644 $autostart_file
    } else {
        log_debug $"Autostart file already exists at ($autostart_file)"
    }

    # Configure rc.xml file
    if not ($rc_file | path exists) {
        log_debug $"Creating rc.xml file: ($rc_file)"
        echo $rc_content | save $rc_file
        # Set proper permissions
        SUDO chmod 644 $rc_file
    } else {
        log_debug $"rc.xml file already exists at ($rc_file)"
    }
    
    log_info "Labwc configuration completed."
}

export def set_config_dir_ownership [] {
    let config_dir = $"/home/mecha/.config"
    log_debug $"Setting ownership of ($config_dir) to mecha:mecha"
    
    let rootfs_dir = $env.ROOTFS_DIR

     # Use chroot to execute gsettings command
    alias CHROOT = sudo chroot $rootfs_dir
    try {
    CHROOT chown -R mecha:mecha $config_dir
    log_info "Ownership set successfully."
    } catch {
     |error| log_error $"Failed to set ownership : ($error)"
    }

    # set permissions to 700
    try {
    CHROOT chmod 700 $config_dir
    log_info "Permissions set successfully."
    } catch {
     |error| log_error $"Failed to set permissions : ($error)"
    }
}

export def configure_mecha_system_pref [] {
    log_info "Configuring system settings:"
    let rootfs_dir = $env.ROOTFS_DIR
    
    # Use chroot to execute gsettings command
    alias CHROOT = sudo chroot $rootfs_dir
    
    #log_debug "Enabling on-screen keyboard system-wide"
    try {
        CHROOT gsettings set org.gnome.desktop.a11y.applications screen-keyboard-enabled true
        log_info "On-screen keyboard enabled system-wide."
    } catch {
        |error|
        log_error "Failed to enable on-screen keyboard system-wide. "
    }
    
    log_debug "Removing unused desktop files"
    # Remove unwanted desktop files
    let files_to_remove = [
        "/usr/share/applications/system-config-printer.desktop",
        "/usr/share/applications/vim.desktop",
        "/usr/share/applications/debian-uxterm.desktop",
        "/usr/share/applications/debian-xterm.desktop",
        "/usr/share/applications/mecha-connect.desktop",
    ]
    
for file in $files_to_remove {
    let file_path = $"($rootfs_dir)($file)"
    if ($file_path | path exists) {
        log_debug $"Removing file: ($file_path)"
        SUDO rm $file_path
    } else {
        log_debug "File not found: ($file_path)"
    }
}
    
    log_info "System-wide settings configuration completed."
}


export def configure_mecha_connect_desktop_file [] {
    log_info "Configuring Mecha Connect desktop entry:"
    let rootfs_dir = $env.ROOTFS_DIR
    
    # Create mecha-connect.desktop file
    let desktop_file_path = $rootfs_dir + "/usr/share/applications/org.mecha.connect.desktop"
    let desktop_file_dir = $rootfs_dir + "/usr/share/applications"
    
    # Remove existing file if it exists
    if ($desktop_file_path | path exists) {
        log_debug $"Removing existing desktop file: ($desktop_file_path)"
        SUDO rm $desktop_file_path
    }
    
    let desktop_file_content = '[Desktop Entry]
Type=Application
TryExec=mecha-connect
Exec=mecha-connect
Icon=/usr/share/mechanix/shell/launcher/assets/icons/app_drawer/mecha_connect_icon.png
Terminal=false
Categories=System;

Name=Connect
GenericName=Connect
Comment=Connect app
    '
    
    # Create desktop entry file
    log_debug $"Writing desktop file to: ($desktop_file_path)"
    # Create empty file with sudo
    SUDO touch $desktop_file_path
    # Write the content
    echo $desktop_file_content | SUDO tee $desktop_file_path out> /dev/null
    # Set appropriate permissions
    SUDO chmod 644 $desktop_file_path
    log_debug "Desktop entry created successfully."
    
    log_info "Mecha Connect desktop configuration completed."
}