#!/usr/bin/env bash
set -euo pipefail

echo "[+] Installing pulp-cli..."
python3 -m pip install --upgrade pip
python3 -m pip install pulp-cli[pygments]

echo "[+] Setting up Pulp CLI config..."
mkdir -p ~/.config/pulp

cat > ~/.config/pulp/cli.toml <<EOF
[cli]
username = "${PULP_USERNAME}"
password = "${PULP_PASSWORD}"
base_url = "${PULP_BASE_URL}"
api_root = "/pulp/"
domain = "default"
headers = []
cert = ""
key = ""
verify_ssl = true
format = "json"
dry_run = false
timeout = 0
verbose = 0
EOF

echo "[+] Verifying Pulp CLI..."
pulp status
