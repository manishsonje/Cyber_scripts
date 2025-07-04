#!/bin/bash
set -e

figlet -f slant "Installing Networking Tools"
LOG="/var/log/networking_tools_setup.log"

echo "Updating package list..." | tee -a $LOG
apt-get update

echo "Installing arp-scan, hydra, nikto, and nmap..." | tee -a $LOG
apt-get install -y arp-scan hydra nikto nmap

echo "Installation is complete" 