#!/bin/bash
set -e

figlet -f slant "Installing BurpSuite Community Edition"
LOG="/var/log/BrupSuite.log"

echo "[BurpSuite]{INFO} --> Checking dependencies…" | tee -a $LOG
for cmd in curl wget grep sed file; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "'$cmd' is required. Install with: sudo apt install $cmd" | tee -a $LOG
    exit 1
  fi
done

echo "[BurpSuite]{INFO} --> Scraping release notes page…" | tee -a $LOG
HTML=$(curl -s https://portswigger.net/burp/releases)

# Extract first matching version line for 'Professional / Community YYYY.M.D' including Linux installer present
LATEST_VERSION=$(echo "$HTML" \
  | grep -oP 'Professional / Community \K[0-9]+\.[0-9]+\.[0-9]+' \
  | head -n1)

if [[ -z "$LATEST_VERSION" ]]; then
  echo " [BurpSuite]{ERROR} -->Could not identify latest version. HTML structure may have changed." | tee -a $LOG
  exit 1
fi

echo "[BurpSuite]{NOTE} -->Latest Burp Suite Community version: $LATEST_VERSION" | tee -a $LOG

INSTALLER="/home/vagrant/burpsuite_community_linux_v${LATEST_VERSION}.sh"
DOWNLOAD_URL="https://portswigger.net/burp/releases/download?product=community&version=${LATEST_VERSION}&type=Linux"

echo "[BurpSuite]{INFO} --> Downloading: $DOWNLOAD_URL" | tee -a $LOG
wget -O "$INSTALLER" "$DOWNLOAD_URL" | tee -a $LOG

if ! file "$INSTALLER" | grep -q "shell script"; then
  echo " [BurpSuite]{ERROR} -->Downloaded file is not a valid installer. Received HTML instead." | tee -a $LOG
  rm -f "$INSTALLER"
  exit 1
fi

chmod +x "$INSTALLER"
echo "[BurpSuite]{NOTE} -->Running installer…" | tee -a $LOG
sh "$INSTALLER"

echo "[BurpSuite]{INFO} -->BrupSuite Installation Completed" | tee -a $LOG
