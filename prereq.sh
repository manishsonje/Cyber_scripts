#Need to command for update and net toll installtion 
#cp brige scripts + LAN ADP settings 

echo "updating Ubuntu before Start"
sudo apt update && sudo apt upgrade
echo "installation of Net Tools"
sudo apt install net-tools

# Check if network rule file exists
usbfile="/etc/udev/rules.d/99-usb-lan.rules" 
pcifile="/etc/udev/rules.d/10-network-custom-names.rules"
 
if [ -f "$usbfile" ]; then
    echo "Found $usbfile with settings"
	sudo chmod 777 $usbfile
elif [-f "$pcifile" ]
	echo "Found $pcifile with settings"
	sudo chmod 777 $pcifile
else
    echo "Did not find network settings, coping both files!"
	sudo cp "/vagrant/*.rules" "/etc/udev/rules.d/"
        sudo chmod 777 $usbfile
        sudo chmod 777 $pcifile
fi
 
#Change permission for file
sudo chmod 777 $rulesfile
 
#reloading rules
sudo udevadm control --reload-rules 
sudo udevadm trigger
 
#copy network utility files to home folder
mkdir -f /home/vagrant/bridge_scripts
cp /vagrant/bridge_scripts/* /home/vagrant/bridge_scripts/