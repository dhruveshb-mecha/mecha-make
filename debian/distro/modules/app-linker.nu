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
    
    # Check if patchelf is available
    try {
        which patchelf | complete
    } catch {
        log_error "patchelf not found. Install it with: sudo apt install patchelf"
        return
    }
    
    # Use chroot to execute commands in the target environment
    alias CHROOT = sudo chroot $rootfs_dir
    
    # Process each app
    for app in ($apps | transpose key value) {
        let bin_name = $app.key
        let lib_dir = $app.value
        let bin_path = $"/usr/bin/($bin_name)"
        let full_bin_path = $rootfs_dir + $bin_path
        let full_lib_path = $rootfs_dir + $lib_dir
        
        log_debug $"Processing ($bin_name)..."
        log_debug $"Binary path: ($full_bin_path)"
        log_debug $"Library path: ($full_lib_path)"
        
        # Check if binary and lib directory exist
        if ($full_bin_path | path exists) and ($full_lib_path | path exists) {
            log_debug $"👉 Patching ($bin_name) to use ($lib_dir)"
            
            try {
                # Use chroot environment to patch the binary
                CHROOT patchelf --set-rpath $lib_dir $bin_path
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
    
    # Verify the configuration by running ldd and logging output
    log_info "Verifying app linking configuration:"
    for app in ($apps | transpose key value) {
        let bin_name = $app.key
        let bin_path = $"/usr/bin/($bin_name)"
        let full_bin_path = $rootfs_dir + $bin_path
        
        if ($full_bin_path | path exists) {
            log_info $"Checking RPATH for ($bin_name):"
            
            try {
                let rpath_output = (CHROOT readelf -d $bin_path | complete)
                if $rpath_output.exit_code == 0 {
                    let rpath_lines = ($rpath_output.stdout | lines | where $it =~ "RPATH|RUNPATH")
                    if ($rpath_lines | length) > 0 {
                        for line in $rpath_lines {
                            log_info $"  RPATH: ($line | str trim)"
                        }
                    } else {
                        log_debug $"  No RPATH found for ($bin_name)"
                    }
                } else {
                    log_debug $"  Failed to read RPATH for ($bin_name)"
                }
            } catch {
                |error| log_debug $"  Could not check RPATH for ($bin_name): ($error)"
            }
            
            # Also run ldd to show library dependencies
            try {
                let ldd_output = (CHROOT ldd $bin_path | complete)
                if $ldd_output.exit_code == 0 {
                    log_info $"Library dependencies for ($bin_name):"
                    let ldd_lines = ($ldd_output.stdout | lines | first 10)  # Limit to first 10 lines
                    for line in $ldd_lines {
                        if ($line | str trim | str length) > 0 {
                            log_info $"  ($line | str trim)"
                        }
                    }
                } else {
                    log_debug $"  Failed to run ldd for ($bin_name): ($ldd_output.stderr)"
                }
            } catch {
                |error| log_debug $"  Could not run ldd for ($bin_name): ($error)"
            }
        }
    }
    
    log_info "App linking configuration completed successfully."
}