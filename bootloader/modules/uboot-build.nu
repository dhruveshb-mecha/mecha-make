
#!/usr/bin/env nu

use logger.nu
use fetch-source.nu

# Global variables
const UBOOT_REPO = "https://github.com/chiragp-mecha/u-boot"

export def build_uboot [uboot_dir:string] {

    log_info "Fetching U-Boot source code"
    fetch_source $UBOOT_REPO ($uboot_dir)

    log_info "Building U-Boot"
    cd ($uboot_dir)
    make clean
    make mecha_comet_defconfig
    make -j (nproc)

    log_info "U-Boot build completed successfully"

    cd $uboot_dir


}