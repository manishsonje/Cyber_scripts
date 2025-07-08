#!/bin/bash

set -e
figlet -f slant "Cyber Patch Installation"
REPO_URL="https://bitbucket.devops.aws.md-man.biz/scm/eeeabb/egen3-setup-tools.git"
script_DIR="/vagrant/Cyber_scripts"

if [ -d "$script_DIR" ]; then
    rm -rf "$script_DIR"
fi
echo "[*] Cloning repository..."
git clone "$REPO_URL" "$script_DIR" 

echo "Making scripts executable"
chmod +x "$script_DIR"/*.sh

# Run scripts in your custom order
SCRIPTS=(
    "prereq.sh"
    "greenboneinstall.sh"
    "greenboneconfig.sh"
    "greenbonefeedsync.sh"
    "burpsuite.sh"
    "networkingtools.sh"
    "x11vnc.sh"
)
echo "Running Cyber_scripts"
for script in "${SCRIPTS[@]}"; do
    echo ">>> Running $script"
    bash "$script_DIR/$script"
    echo ">>> Finished $script"
    echo "----------------------"
done

echo "[✓] All scripts executed in custom order."
