#!/bin/bash
set -e

# Run this Script with "sudo"

figlet -f slant "Installing GreenBone"
LOG="/var/log/GreenboneOpenVas.sh"

# Function to check if a command exists
command_exists() {
  command -v "$1" &>/dev/null
}
echo "[Greenbone]{INFO} --> Checking for Docker..." | tee -a $LOG
if command_exists docker; then
  echo "[Greenbone]{NOTE} -->Docker is already installed." | tee -a $LOG
else
  echo "[Greenbone]{INFO} --> Installing Docker..." | tee -a $LOG
  apt update
  apt install -y apt-transport-https ca-certificates curl software-properties-common
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
  add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
  apt update
  apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  echo "[Greenbone]{NOTE} --> Docker installation complete." | tee -a $LOG
fi

DOWNLOAD_DIR="$HOME/greenbone-community-container"
COMPOSE_FILE="$DOWNLOAD_DIR/docker-compose.yml"
GREENBONE_URL="https://greenbone.github.io/docs/latest/_static/docker-compose.yml"
MAX_RETRIES=10

echo "[Greenbone]{INFO} --> Creating download directory at: $DOWNLOAD_DIR" | tee -a $LOG
mkdir -p "$DOWNLOAD_DIR"

echo "[Greenbone]{INFO} --> Downloading docker-compose.yml..." | tee -a $LOG
if ! curl -f -L "$GREENBONE_URL" --output "$COMPOSE_FILE"; then
  echo "[Greenbone]{ERROR} --> Failed to download docker-compose.yml from $GREENBONE_URL" | tee -a $LOG
  exit 1
fi

echo "[Greenbone]{INFO} --> Pulling Greenbone Docker images..." | tee -a $LOG
attempt=1
while [ "$attempt" -le "$MAX_RETRIES" ]; do
  echo "[Greenbone]{NOTE} --> Attempt $attempt of $MAX_RETRIES..." | tee -a $LOG
  pull_output=$(docker compose -f "$COMPOSE_FILE" pull 2>&1) && break

  if echo "$pull_output" | grep -q "pull access denied"; then 
    echo "[Greenbone]{INFO} -->Pull access denied. Retrying in 5 seconds..." | tee -a $LOG
    sleep 5
    attempt=$((attempt + 1))
  else
    echo "$pull_output" | tee -a $LOG
    echo "[Greenbone]{ERROR} --> Unknown error occurred during docker pull" | tee -a $LOG
    exit 2
  fi
done

if [ "$attempt" -gt "$MAX_RETRIES" ]; then
  echo "[Greenbone]{ERROR} --> Failed to pull images after $MAX_RETRIES attempts. Check registry access:" | tee -a $LOG
  echo "    registry.community.greenbone.net might be down or restricted." | tee -a $LOG
  exit 3
fi

echo "[Greenbone]{INFO} --> Starting Greenbone containers..."  | tee -a $LOG
docker compose -f "$COMPOSE_FILE" up -d

echo "[Greenbone]{NOTE} --> Setting user credentials" | tee -a $LOG
docker compose -f "$COMPOSE_FILE" exec -T -u gvmd gvmd gvmd --user=admin --new-password='admin123'

echo "[Greenbone]{INFO} --> Greenbone Community Edition installation completed!" | tee -a $LOG

echo "###################################################" | tee -a $LOG
echo " Greenbone is available on http://localhost:9392   " | tee -a $LOG
echo " Wait unitl the plugin & Data Base are Updated     " | tee -a $LOG
echo " Check README file for Login Credentials           " | tee -a $LOG
echo "###################################################" | tee -a $LOG

echo "[Greenbone]{ATTENTION} -->Opening Web Interface" | tee -a $LOG
xdg-open "http://localhost:9392" 2>/dev/null >/dev/null &