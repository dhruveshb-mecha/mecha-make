#!/usr/bin/env nu

use logger.nu


export def create_dir_if_not_exist [dir: string] {
    let check_if_path_exists: bool =   ($dir | path exists)
    if $check_if_path_exists {
        log_info $"Directory ($dir) already exists"
    } else {
        log_info $"Creating directory ($dir)"
        mkdir $dir
    }
   
}

export def collect_artifacts [source_dir:string, deploy_dir:string] {
    log_info "Collecting artifacts"
    let deploy_dir = $env.DEPLOY_DIR
    let work_dir = $env.WORK_DIR

    let mkimage_dir = ($work_dir | path join "imx-mkimage" "iMX8M" "flash.bin")
    cp $mkimage_dir $deploy_dir
}