#!/usr/bin/env nu

use logger.nu

alias SUDO = sudo

# Configure RPATH for Mechanix apps so each binary uses its own lib folder
export def configure_app_linking [] {
    log_info "Configuring app linking (RPATH):"
    let rootfs_dir = $env.ROOTFS_DIR
    
    # Map of binaries to matching lib directories
    let apps = {
        mechanix_files: "/usr/share/mechanix/mechanix-files-beta/lib"
        mechanix_notes: "/usr/share/mechanix/mechanix-notes-beta/lib" 
        mechanix_settings: "/usr/share/mechanix/mechanix-settings-beta/lib"
    }
    
    # Build paths using your approach
    let rootfs_dir = $rootfs_dir | path expand
    
    # Check if patchelf is available on HOST, install if missing
    try {
        which patchelf
        log_debug "patchelf found on host"
    } catch {
        log_info "patchelf not found on host, installing it..."
        try {
            sudo apt-get update -qq
            sudo apt-get install -y patchelf
            log_info "Successfully installed patchelf on host"
        } catch {
            log_error "Failed to install patchelf on host"
            return
        }
    }
    
    # Process each app using HOST patchelf
    for app in ($apps | transpose key value) {
        let bin_name = $app.key
        let lib_dir = $app.value
        let full_bin_path = $rootfs_dir + $"/usr/bin/($bin_name)"
        let full_lib_path = $rootfs_dir + $lib_dir
        
        log_debug $"Processing ($bin_name)..."
        
        # Check if binary and lib directory exist
        if ($full_bin_path | path exists) and ($full_lib_path | path exists) {
            log_debug $"👉 Patching ($bin_name) to use ($lib_dir)"
            
            try {
                patchelf --set-rpath $lib_dir $full_bin_path
                log_info $"✅ Successfully patched ($bin_name)"
            } catch {
                |error| log_error $"❌ Failed to patch ($bin_name): ($error)"
            }
        } else {
            if not ($full_bin_path | path exists) {
                log_debug $"⚠️ Binary not found: ($full_bin_path)"
            }
            if not ($full_lib_path | path exists) {
                log_debug $"⚠️ Lib directory not found: ($full_lib_path)"
            }
            log_debug $"⚠️ Skipping ($bin_name) (binary or libdir missing)"
        }
    }
    
    log_info "App linking configuration completed successfully."
}