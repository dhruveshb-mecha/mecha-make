#!/usr/bin/env nu

use logger.nu
use fetch-source.nu

export def build_imx_mkimage [work_dir:string] {
    log_info "Building IMX MKIMAGE"
    let mkimage_dir = ($work_dir + "/imx-mkimage") | path expand
    mkdir $mkimage_dir

    let manifest = "../manifest/mecha-comet-m-gen1.yml" | path expand
    let IMX_MKIMAGE_REPO = open $manifest | get imx-mkimage | get url

    log_debug $"Fetching IMX MKIMAGE source code from ($IMX_MKIMAGE_REPO) to ($mkimage_dir)"
    curl -L $IMX_MKIMAGE_REPO | tar -xz -C $mkimage_dir --strip-components=1

    log_info "IMX MKIMAGE build completed successfully"
    cd $work_dir
}