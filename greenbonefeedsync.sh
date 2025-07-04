#!/bin/bash
set -e
figlet -f slant "GreenBone  Feed Sync"

#Update Network Vulnerability Tests (NVTs)	

echo "Update Network Vulnerability Tests (NVTs)" | tee -a $LOG
echo "gvm ALL = NOPASSWD: $(which openvas)" | sudo tee -a /etc/sudoers.d/gvm
sudo -Hiu gvm greenbone-nvt-sync --rsync-timeout 300 
echo "Updating the Plugins into Redius server" | tee -a $LOG
sudo -Hiu gvm sudo openvas --update-vt-info
sudo chown -R gvm:gvm /var/log/gvm

#Keeping the feeds up-to-date
echo "Keeping the feeds up-to-date" | tee -a $LOG

sudo -Hiu gvm greenbone-feed-sync --type GVMD_DATA --rsync-timeout 300 
sudo -Hiu gvm greenbone-feed-sync --type SCAP --rsync-timeout 300
sudo -Hiu gvm greenbone-feed-sync --type CERT --rsync-timeout 300


#Configure GVM Feed Validation
echo "Configure GVM Feed Validation" | tee -a  $LOG
wget https://www.greenbone.net/GBCommunitySigningKey.asc
sudo gpg --homedir=/etc/openvas/gnupg --import GBCommunitySigningKey.asc
echo "8AE4BE429B60A59B311C2E739823FAA60ED1E580:6:" | sudo gpg --import-ownertrust --homedir=/etc/openvas/gnupg
sudo -Hiu gvm gpg --homedir=/etc/openvas/gnupg --list-keys
echo "--------------------------------------------------------------------------"
echo "GreenBone Feed-Sync Complete"