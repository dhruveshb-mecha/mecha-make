#!/usr/bin/env nu

use std log

let base_url = "http://167.235.132.100:8080/pulp/content/file/comet"

let files = [
  "initramfs/comet/rev3/mecha-comet-m-gen1-mfgtool-initramfs.cpio.gz.u-boot"
  "kernel/comet/common/6.12-Image"
  "bootloader/comet/rev3/flash.bin"
  "script/comet/rev3/flash.auto"
  "dtb/imx8mm/comet/rev3/imx8mm-mecha-comet-m-gen1.dtb"
  "rootfs/debian/comet/rev3/debian-image-rootfs.tar.gz"
]

def download_file [url: string, filename: string] {
  log info $"Downloading ($filename) from ($url)"
  print $"→ Downloading: ($filename)\n"

  try {
    ^curl --progress-bar -fL $url -o $filename
    log info $"✓ Successfully downloaded ($filename)"
  } catch {
    log error $"✗ Failed to download ($filename)"
    print $"ERROR: Failed to download ($filename)\n"
  }
}

def main [] {
  log info "=== Starting download process ==="
  print "Files to download:\n"

  # Display filenames and URLs
  for path in $files {
    let filename = ($path | path basename)
    let url = $"($base_url)/($path)"
    print $"  - ($filename): ($url)"
  }

  print "\nStarting downloads...\n"

  # Download loop
  for path in $files {
    let filename = ($path | path basename)
    let url = $"($base_url)/($path)"
    download_file $url $filename
  }

  print "\n✅ All downloads complete.\n"
  log info "=== Download process finished ==="
}