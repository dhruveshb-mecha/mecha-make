#!/bin/bash

set -euo pipefail

BASE_URL="http://167.235.132.100:8080/pulp/content/file/comet"

FILES=(
  "initramfs/comet/rev3/mecha-comet-m-gen1-mfgtool-initramfs.cpio.gz.u-boot"
  "kernel/comet/common/6.12-Image"
  "bootloader/comet/rev3/flash.bin"
  "script/comet/rev3/flash.auto"
  "dtb/imx8mm/comet/rev3/imx8mm-mecha-comet-m-gen1.dtb"
  "rootfs/debian/comet/rev3/debian-image-rootfs.tar.gz"
)

LOG_FILE="download.log"

log() {
  local level="$1"
  local msg="$2"
  local timestamp
  timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  echo -e "[$timestamp] [$level] $msg" | tee -a "$LOG_FILE"
}

download_file() {
  local url="$1"
  local filename
  filename=$(basename "$url")

  log "INFO" "Starting download: $filename"

  # Use curl with --progress-bar and force it to write to terminal
  if curl --progress-bar -fL "$url" -o "$filename" | tee -a "$LOG_FILE"; then
    log "SUCCESS" "Downloaded: $filename"
  else
    log "ERROR" "Failed to download: $filename"
  fi
}

main() {
  log "INFO" "Download script started."
  log "INFO" "Saving files to: $(pwd)"
  echo

  for path in "${FILES[@]}"; do
    full_url="$BASE_URL/$path"
    echo "Downloading: $(basename "$path")"
    download_file "$full_url"
    echo
  done

  log "INFO" "Download script finished."
}

main