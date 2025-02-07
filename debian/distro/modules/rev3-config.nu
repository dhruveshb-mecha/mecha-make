#!/usr/bin/env nu

use logger.nu

alias SUDO = sudo

# Configuring settings for rev3 board mecha comet
export def configure_rev3 [] {
log_info "Configuring settings for rev3"

let rootfs_dir = $env.ROOTFS_DIR
let build_conf_path = $env.BUILD_CONF_PATH

let script_dir_path =  (open $build_conf_path | get include-path)
alias CHROOT = sudo chroot $rootfs_dir

let rev3_dtb_config_src = $script_dir_path + "/imx8mm-mecha-comet-m-gen1-rev3.dtb"
let rev3_dtb_config_dest = $rootfs_dir + "/usr/lib/linux-image-6.6.36+mecha+/freescale/imx8mm-mecha-comet-m-gen1.dtb"


log_debug $"Copying ($rev3_dtb_config_src) to ($rev3_dtb_config_dest)"
SUDO cp $rev3_dtb_config_src $rev3_dtb_config_dest 

}