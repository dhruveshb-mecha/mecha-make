#!/usr/bin/env nu

# Fail early
let-env PULP_USERNAME = $env.PULP_USERNAME
let-env PULP_PASSWORD = $env.PULP_PASSWORD
let-env PULP_BASE_URL = $env.PULP_BASE_URL

print "[+] Installing pulp-cli..."
python3 -m pip install --upgrade pip
python3 -m pip install 'pulp-cli[pygments]'

print "[+] Setting up Pulp CLI config..."
mkdir ~/.config/pulp

let config = {
  cli: {
    username: $PULP_USERNAME
    password: $PULP_PASSWORD
    base_url: $PULP_BASE_URL
    api_root: "/pulp/"
    domain: "default"
    headers: []
    cert: ""
    key: ""
    verify_ssl: true
    format: "json"
    dry_run: false
    timeout: 0
    verbose: 0
  }
}

# Save config to TOML
$config | to toml | save --force ~/.config/pulp/cli.toml

print "[+] Verifying Pulp CLI..."
pulp status
