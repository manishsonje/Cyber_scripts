#!/bin/bash

set -e
figlet -f slant "Installing BurpSuite Community Edition"
echo "Checking dependencies…"
for cmd in curl wget grep sed file; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "'$cmd' is required. Install with: sudo apt install $cmd"
    exit 1
  fi
done

echo "Scraping release notes page…"
HTML=$(curl -s https://portswigger.net/burp/releases)

# Extract first matching version line for 'Professional / Community YYYY.M.D' including Linux installer present
LATEST_VERSION=$(echo "$HTML" \
  | grep -oP 'Professional / Community \K[0-9]+\.[0-9]+\.[0-9]+' \
  | head -n1)

if [[ -z "$LATEST_VERSION" ]]; then
  echo "Could not identify latest version. HTML structure may have changed."
  exit 1
fi

echo "Latest Burp Suite Community version: $LATEST_VERSION"

INSTALLER="/home/vagrant/burpsuite_community_linux_v${LATEST_VERSION}.sh"
DOWNLOAD_URL="https://portswigger.net/burp/releases/download?product=community&version=${LATEST_VERSION}&type=Linux"

echo "Downloading: $DOWNLOAD_URL"
wget -O "$INSTALLER" "$DOWNLOAD_URL"

if ! file "$INSTALLER" | grep -q "shell script"; then
  echo "Downloaded file is not a valid installer. Received HTML instead."
  rm -f "$INSTALLER"
  exit 1
fi

chmod +x "$INSTALLER"
echo "Running installer…"
sh "$INSTALLER"
