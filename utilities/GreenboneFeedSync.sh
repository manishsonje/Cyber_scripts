#!/bin/bash
set -e

# Run this Script with "sudo"

figlet -f slant "GreenBone FeedSync"

DOWNLOAD_DIR="$HOME/greenbone-community-container"
COMPOSE_FILE="$DOWNLOAD_DIR/docker-compose.yml"
echo "[CyberENV]{INFO} --> Greenbone FeedSync Started"
docker compose -f $COMPOSE_FILE pull notus-data vulnerability-tests scap-data dfn-cert-data cert-bund-data report-formats data-objects
docker compose -f $COMPOSE_FILE up -d notus-data vulnerability-tests scap-data dfn-cert-data cert-bund-data report-formats data-objectsx
echo "[GreenBone]{INFO} --> Greenbone FeedSync completed!" 