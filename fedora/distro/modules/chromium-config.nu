#!/usr/bin/env nu

use logger.nu

alias SUDO = sudo

export def configure_chromium_preferences [] {
    log_info "Configuring Chromium preferences:"
    let rootfs_dir = $env.ROOTFS_DIR
    
    # Define the paths relative to rootfs
    let master_prefs_dir = $"($rootfs_dir)/etc/chromium"
    let master_prefs_file = $"($master_prefs_dir)/master_preferences"
    let policies_dir = $"($rootfs_dir)/etc/chromium/policies/managed"
    let policy_file = $"($policies_dir)/chromium-policy.json"
    
    # Create directories if they don't exist
    for dir in [$master_prefs_dir $policies_dir] {
        if not ($dir | path exists) {
            log_debug $"Creating directory: ($dir)"
            SUDO mkdir -p $dir
        }
    }
    
    # Define the master preferences content as a string to ensure proper JSON format
    let master_prefs_content = '{
        "homepage": "http://www.google.com",
        "homepage_is_newtabpage": false,
        "browser": {
            "show_home_button": true
        },
        "session": {
            "restore_on_startup": 4,
            "startup_urls": [
                "http://www.google.com/"
            ]
        },
        "bookmark_bar": {
            "show_on_all_tabs": false
        },
        "sync_promo": {
            "show_on_first_run_allowed": false
        },
        "distribution": {
            "import_bookmarks_from_file": "bookmarks.html",
            "import_bookmarks": true,
            "import_history": true,
            "import_home_page": true,
            "import_search_engine": true,
            "ping_delay": 60,
            "do_not_create_desktop_shortcut": true,
            "do_not_create_quick_launch_shortcut": true,
            "do_not_create_taskbar_shortcut": true,
            "do_not_launch_chrome": true,
            "do_not_register_for_update_launch": true,
            "make_chrome_default": true,
            "make_chrome_default_for_user": true,
            "system_level": true,
            "verbose_logging": true,
            "browser": {
                "confirm_to_quit": true
            }
        },
        "first_run_tabs": [
            "https://mecha.so/",
            "http://new_tab_page"
        ]
    }'
    
    # Define the policy content as a string to ensure proper JSON format
    let policy_content = '{
        "HomepageLocation": "https://www.google.com",
        "RestoreOnStartup": 4,
        "BlockOutdatedPlugins": true,
        "DisableJavaScript": false,
        "IncognitoModeAvailability": 1,
        "ForceDarkMode": true,
        "ShowHomeButton": true,
        "Color": "#2B2B2B",
        "ForceFirstRun": true,
        "BrowserThemeColor": "#2B2B2B"
    }'
    
    # Write master preferences file
    log_debug $"Writing master preferences to: ($master_prefs_file)"
    echo $master_prefs_content | SUDO tee $master_prefs_file
    SUDO chmod 644 $master_prefs_file
    
    # Write policy file
    log_debug $"Writing policy file to: ($policy_file)"
    echo $policy_content | SUDO tee $policy_file
    SUDO chmod 644 $policy_file


    # Create chromium.desktop file
    let desktop_file_path = $rootfs_dir + "/usr/share/applications/chromium.desktop"
    let desktop_file_dir = $rootfs_dir + "/usr/share/applications"

    # Remove existing file if it exists
    if ($desktop_file_path | path exists) {
        log_debug $"Removing existing desktop file: ($desktop_file_path)"
        SUDO rm $desktop_file_path
    }

    let desktop_file_content = '[Desktop Entry]
Type=Application
TryExec=chromium
Exec=sh -c "export DISPLAY=:0 && chromium"
Icon=/usr/share/mechanix/shell/launcher/assets/icons/app_drawer/chromium_icon.png
Terminal=false
Categories=System;
Name=Chromium
GenericName=Chromium
Comment=Browser app
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

    
    log_info "Chromium configuration completed."
}