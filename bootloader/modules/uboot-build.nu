
#!/usr/bin/env nu

use logger.nu *
use fetch-source.nu *


export def build_uboot [uboot_dir:string] {

    let manifest = "../manifest/mecha-comet-m-gen1.yml" | path expand

    #let UBOOT_REPO = open $manifest | get u-boot | get url

    let $UBOOT_REPO = "git@github.com:chiragp-mecha/u-boot.git"

    let work_dir = "../u-boot";

    log_debug $"Building U-Boot"
    log_debug "Fetching U-Boot source code and extracting it"
    #fetch_source $UBOOT_REPO $uboot_dir
    #curl -L $UBOOT_REPO | tar -xz -C ($uboot_dir) --strip-components=1

    log_info "Building U-Boot"
    cd /home/mecha-4/build-2/work
    git clone git@github.com:chiragp-mecha/u-boot.git
    cd u-boot
    git checkout imx-2023.04.y
    make clean
    make mecha_cometm_gen1_defconfig
    make -j (nproc)

    log_info "U-Boot build completed successfully"

    cd /home/mecha-4/build-2/work


}