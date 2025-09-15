#!/usr/bin/env nu

use logger.nu

alias SUDO = sudo

export def configure_kanshi [] {
    log_info "Configuring kanshi:"
    let rootfs_dir = $env.ROOTFS_DIR
    
    let config_dir = $"($rootfs_dir)/home/mecha/.config"
    let kanshi_config_dir = $"($config_dir)/kanshi"
    let kanshi_config_file = $"($kanshi_config_dir)/config"

    # User-level configuration
    log_info "Setting up user kanshi configuration..."
    
    # Create config directory if it doesn't exist
    if not ($kanshi_config_dir | path exists) {
        log_debug $"Creating directory: ($kanshi_config_dir)"
        mkdir $kanshi_config_dir
    }
    
    # Define kanshi configuration content
    let kanshi_config_content = 'profile {
    output DSI-1 enable scale 2
}
'

    # Check if config file exists and remove it
    if ($kanshi_config_file | path exists) {
        log_debug $"Removing existing kanshi config: ($kanshi_config_file)"
        rm $kanshi_config_file
    }

    # Create kanshi config file
    log_debug $"Writing kanshi config to: ($kanshi_config_file)"
    echo $kanshi_config_content | save $kanshi_config_file
    log_info "kanshi config file created successfully."

    log_debug "Kanshi configuration completed successfully."
}