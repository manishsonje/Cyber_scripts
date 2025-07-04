#!/bin/bash
set -e
figlet -f slant "Installing x11vnc Server"

LOG="/var/log/vnc_tools_setup1.log"


echo "Installing x11vnc..." | tee -a $LOG
apt-get install -y x11vnc

echo "Creating x11vnc systemd service..." | tee -a $LOG
cat > /lib/systemd/system/x11vnc.service <<EOF
[Unit]
Description=x11vnc
After=display-manager.service network.target syslog.target

[Service]
Type=simple
ExecStart=/usr/bin/x11vnc -forever -display :0 -auth guess -forever -shared -passwd vagrant
ExecStop=/usr/bin/killall x11vnc
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF


echo "Updating gdm3 custom.conf" |  tee -a $LOG
cat >  /etc/gdm3/custom.conf <<EOF

# GDM configuration storage
#
# See /usr/share/gdm/gdm.schemas for a list of available options.

[daemon]
# Uncomment the line below to force the login screen to use Xorg
WaylandEnable=false

# Enabling automatic login
AutomaticLoginEnable = true
AutomaticLogin = vagrant

# Enabling timed login
#  TimedLoginEnable = true
#  TimedLogin = user1
#  TimedLoginDelay = 10

[security]

[xdmcp]

[chooser]

[debug]
# Uncomment the line below to turn on debugging
# More verbose logs
# Additionally lets the X server dump core if it crashes
#Enable=true
EOF

echo "systemctl command" | tee -a $LOG
systemctl daemon-reload
systemctl enable x11vnc.service
systemctl start x11vnc.service
sudo reboot 

