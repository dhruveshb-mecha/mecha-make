import os
import yaml
import hashlib
import argparse
import zipfile
import logging
from datetime import datetime, timezone # Import timezone

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s"
)

# CLI arguments
parser = argparse.ArgumentParser(description="Create a manifest and zip build artifacts.")
parser.add_argument("--id", required=True)
parser.add_argument("--version", required=True)
parser.add_argument("--channel", required=True)
parser.add_argument("--machine", required=True)
parser.add_argument("--gen", required=True)
parser.add_argument("--rev", required=True)
args = parser.parse_args()

# Manifest schema
manifest = {
    "id": args.id,
    "version": args.version,
    "channel": args.channel,
    "created_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"), # Changed line
    "description": "",
    "url": "",
    "machine": {
        "name": args.machine,
        "gen": args.gen,
        "rev": args.rev
    },
    "packages": {
        "rootfs":   {"name": "", "version": "", "size": None, "sha2": ""},
        "uboot":    {"name": "", "version": "", "size": None, "sha2": ""},
        "linux":    {"name": "", "version": "", "size": None, "sha2": ""},
        "dtb":      {"name": "", "version": "", "size": None, "sha2": ""},
        "script":   {"name": "", "version": "", "size": None, "sha2": ""},
        "mfgtools": {"name": "", "version": "", "size": None, "sha2": ""}
    }
}

# File patterns to identify components
keywords = {
    "rootfs": [".tar.gz"],
    "uboot": [".bin"],
    "linux": ["linux", "Image"],
    "dtb": [".dtb"],
    "script": [".auto"],
    "mfgtools": [".u-boot"]
}

def sha256_hash(filename):
    logging.debug(f"Computing SHA256 for {filename}")
    sha256 = hashlib.sha256()
    with open(filename, "rb") as f:
        for block in iter(lambda: f.read(4096), b""):
            sha256.update(block)
    return sha256.hexdigest()

# Identify and populate package info
files = os.listdir()
logging.info("Scanning files in the current directory...")

for component, patterns in keywords.items():
    found = False
    for pattern in patterns:
        for file in files:
            if pattern in file:
                logging.info(f"Matched {component} file: {file}")
                manifest["packages"][component]["name"] = file
                manifest["packages"][component]["version"] = file.split("-")[-1].split(".")[0]
                manifest["packages"][component]["size"] = os.path.getsize(file)
                manifest["packages"][component]["sha2"] = sha256_hash(file)
                found = True
                break
        if found:
            break
    if not found:
        logging.warning(f"No matching file found for component '{component}'")

# Write manifest to YAML file
manifest_file = "manifest.yml"
logging.info(f"Writing manifest to {manifest_file}")
with open(manifest_file, "w") as f:
    yaml.dump(manifest, f, sort_keys=False)

# Create ZIP archive
zip_name = f"{args.machine}-gen{args.gen}-rev{args.rev}-v{args.version}.zip"
logging.info(f"Creating ZIP archive: {zip_name}")

with zipfile.ZipFile(zip_name, "w") as zipf:
    for component, pkg in manifest["packages"].items():
        file = pkg["name"]
        if file and os.path.exists(file):
            logging.info(f"Adding {file} to archive")
            zipf.write(file)
        else:
            logging.warning(f"File for {component} not found or not set, skipping")
    zipf.write(manifest_file)

logging.info("Done.")