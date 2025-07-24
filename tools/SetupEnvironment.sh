#!/bin/bash
set -e

figlet -f slant "Setting up Cyber ENV"

USBFILE="99-usb-lan.rules"
PCIFILE="10-network-custom-names.rules"
TARGET_DIR="/etc/udev/rules.d"
IFCONFIG_MACS=$(ifconfig | grep -o -i -E '([0-9A-F]{2}:){5}[0-9A-F]{2}')
LOG="/var/log/setupenv.log"

PCI_COUNT=$(lshw -class network | grep 'pci@' | wc -l)
USB_COUNT=$(lshw -class network | grep 'usb@' | wc -l)
#-------------------------------------------------------------------------------------------------------------------------------------------------

# Check adapter count and create flag file
echo "[CyberENV]{INFO} --> Checking the Rules file are modified" | tee -a $LOG
if [ "$PCI_COUNT" -ge 10 ]; then
    echo "[CyberENV]{INFO} --> Checking MACs in $TARGET_DIR/$PCIFILE"
    MISSING_MACS=$(grep -o -i -E '([0-9A-F]{2}:){5}[0-9A-F]{2}' "$TARGET_DIR/$PCIFILE" | while read mac; do
        echo "$IFCONFIG_MACS" | grep -iq "$mac" || echo "$mac"
    done)

    if [ -z "$MISSING_MACS" ] && [ -f "$TARGET_DIR/$PCIFILE" ]; then
        echo "[CyberENV]{NOTE} --> $TARGET_DIR/$PCIFILE File is modified By User"
    else
		echo "[CyberENV]{ERROR} --> File is not modified and not present at "$TARGET_DIR"."
		echo "[CyberENV]{ATTENTION} --> Please update the MAC addresses and re-run Cyber Environment  script."
        exit 1
    fi

elif [ "$USB_COUNT" -ge 10 ]; then
    echo "[CyberENV]{INFO} --> Checking MACs in $TARGET_DIR/$USBFILE"
    MISSING_MACS=$(grep -o -i -E '([0-9A-F]{2}:){5}[0-9A-F]{2}' "$TARGET_DIR/$USBFILE" | while read mac; do
        echo "$IFCONFIG_MACS" | grep -iq "$mac" || echo "$mac"
    done)

    if [ -z "$MISSING_MACS" ] && [ -f "$TARGET_DIR/$USBFILE" ]; then
        echo "[CyberENV]{NOTE} --> $TARGET_DIR/$USBFILE File is modified By User"
    else
        echo "[CyberENV]{ERROR} File is not modified not present at "$TARGET_DIR"."
		echo "[CyberENV]{ATTENTION} --> Please update the MAC addresses and re-run this script."
        exit 1
    fi

else
    echo "[CyberENV]{ATTENTION} --> No sufficient adapters found." | tee -a $LOG
    echo "[CyberENV]{NOTE} --> USB devices: $USB_COUNT, PCI devices: $PCI_COUNT" | tee -a $LOG
    echo "[CyberENV]{ATTENTION} --> Please connect additional network adapters." | tee -a $LOG	
	exit 1
fi
#-------------------------------------------------------------------------------------------------------------------------------------------------

# System update
echo "[CyberENV]{INFO} --> Updating Ubuntu before Start..." | tee -a $LOG
apt update

# Install networking tools
echo "[CyberENV]{INFO} --> Installing arp-scan, hydra, nikto..." | tee -a $LOG
apt-get install -y arp-scan hydra nikto
#--------------------------------------------------------------------------------------------------------------------------------------------------

# LAN Adapter settings
echo "[CyberENV]{NOTE} --> Setting Up LAN Adapter..." | tee -a $LOG

if [ -f "$TARGET_DIR/$PCIFILE" ]; then
    echo "[CyberENV]{INFO} --> PCI devices: $PCI_COUNT — setting permission for $PCIFILE" | tee -a $LOG
    chmod 644 "$TARGET_DIR/$PCIFILE"
elif [ -f "$TARGET_DIR/$USBFILE" ]; then
    echo "[CyberENV]{INFO} --> USB devices: $USB_COUNT — setting permission for $USBFILE" | tee -a $LOG
    chmod 644 "$TARGET_DIR/$USBFILE"
else
    echo "[CyberENV]{ATTENTION} --> Adapter file not found in target directory: $PCIFILE or $USBFILE" | tee -a $LOG
fi

# Reload UDEV rules
echo ("[CyberENV]{INFO} --> Reloading UDEV rules") 
udevadm control --reload-rules 
udevadm trigger

#-------------------------------------------------------------------------------------------------------------------------------------------------
# Copy bridge scripts
echo "[CyberENV]{NOTE} --> Copying bridge scripts to home folder..." | tee -a $LOG
cp -r "/tmp/egen3-setup-tools/cyber_scripts/bridge_scripts" "$HOME/bridge_scripts"
chmod +x $HOME/bridge_scripts/*.sh

#Crating Symlink for bridge_scripts folder
echo "[CyberENV]{INFO} --> Creating Symlink for bridge_scripts folder" | tee -a $LOG

for symlink in $HOME/bridge_scripts/*.sh; do
  TARGET="/usr/local/bin/$(basename "${symlink%.sh}")"
  ln -sf "$symlink" "$TARGET"
  echo "$TARGET -> $symlink" >> $HOME/Symlink.txt
done

echo "[CyberENV]{INFO} --> Cyber Environment setup is completed for the system." | tee -a $LOG