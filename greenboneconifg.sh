#!/bin/bash
set -e
figlet -f slant "GreenBone Configuration"

#Running OpenVAS Scanner, GSA and GVM services
echo "Running OpenVAS Scanner, GSA and GVM services" | tee -a  $LOG
echo "Create Systemd Service unit for OpenVAS OSPD" | tee -a $LOG
sudo tee /etc/systemd/system/ospd-openvas.service <<EOL
[Unit]
Description=OSPd Wrapper for the OpenVAS Scanner (ospd-openvas)
Documentation=man:ospd-openvas(8) man:openvas(8)
After=network.target networking.service redis-server@openvas.service mosquitto.service
Wants=redis-server@openvas.service mosquitto.service
ConditionKernelCommandLine=!recovery

[Service]
Type=exec
User=gvm
Group=gvm
RuntimeDirectory=ospd
RuntimeDirectoryMode=2775
PIDFile=/run/ospd/ospd-openvas.pid
Environment="PYTHONPATH=/usr/local/lib/python3.12/site-packages/"
ExecStartPre=-rm -rf /run/ospd/ospd-openvas.pid /run/ospd/ospd-openvas.sock
ExecStart=/usr/local/bin/ospd-openvas --foreground \
	--unix-socket /run/ospd/ospd-openvas.sock \
	--pid-file /run/ospd/ospd-openvas.pid \
	--log-file /var/log/gvm/ospd-openvas.log \
	--lock-file-dir /var/lib/openvas \
	--socket-mode 0770 \
	--mqtt-broker-address localhost \
	--mqtt-broker-port 1883 \
	--notus-feed-dir /var/lib/notus/advisories
SuccessExitStatus=SIGKILL
Restart=always
RestartSec=60

[Install]
WantedBy=multi-user.target
EOL

sudo systemctl daemon-reload
sudo systemctl enable --now ospd-openvas
systemctl --no-pager status ospd-openvas.service

echo "--------------------------------------------------------------------------"
#Create Notus Scanner Systemd Service Unit
echo "Create Notus Scanner Systemd Service Unit" | tee -a $LOG
sudo tee /etc/systemd/system/notus-scanner.service << 'EOL'
[Unit]
Description=Notus Scanner
After=mosquitto.service
Wants=mosquitto.service
ConditionKernelCommandLine=!recovery

[Service]
Type=exec
User=gvm
RuntimeDirectory=notus-scanner
RuntimeDirectoryMode=2775
PIDFile=/run/notus-scanner/notus-scanner.pid
Environment="PYTHONPATH=/usr/local/lib/python3.12/site-packages/"
ExecStart=/usr/local/bin/notus-scanner --foreground \
	--products-directory /var/lib/notus/products \
	--log-file /var/log/gvm/notus-scanner.log
SuccessExitStatus=SIGKILL
Restart=always
RestartSec=60

[Install]
WantedBy=multi-user.target
EOL

sudo systemctl daemon-reload
sudo systemctl enable --now notus-scanner
systemctl --no-pager status notus-scanner
echo "--------------------------------------------------------------------------"
#Creating Systemd Service units for GVM services
echo "Creating Systemd Service units for GVM services" | tee -a $LOG
sudo cp /usr/local/lib/systemd/system/gvmd.service{,.bak}
sudo tee /usr/local/lib/systemd/system/gvmd.service << 'EOL'
[Unit]
Description=Greenbone Vulnerability Manager daemon (gvmd)
After=network.target networking.service postgresql.service ospd-openvas.service
Wants=postgresql.service ospd-openvas.service
Documentation=man:gvmd(8)
ConditionKernelCommandLine=!recovery

[Service]
Type=exec
User=gvm
Group=gvm
PIDFile=/run/gvmd/gvmd.pid
RuntimeDirectory=gvmd
RuntimeDirectoryMode=2775
ExecStart=/usr/local/sbin/gvmd --foreground \
	--osp-vt-update=/run/ospd/ospd-openvas.sock \
	--listen-group=gvm
Restart=always
TimeoutStopSec=10

[Install]
WantedBy=multi-user.target
EOL

sudo systemctl daemon-reload
sudo systemctl enable --now gvmd
systemctl --no-pager status gvmd
echo "--------------------------------------------------------------------------"
#Creating Systemd Service units for GSA services
echo "Creating Systemd Service units for GSA services" | tee -a $LOG
sudo cp /usr/local/lib/systemd/system/gsad.service{,.bak}
sudo tee /usr/local/lib/systemd/system/gsad.service << 'EOL'
[Unit]
Description=Greenbone Security Assistant daemon (gsad)
Documentation=man:gsad(8) https://www.greenbone.net
After=network.target gvmd.service
Wants=gvmd.service

[Service]
Type=exec
User=gvm
Group=gvm
RuntimeDirectory=gsad
RuntimeDirectoryMode=2775
PIDFile=/run/gsad/gsad.pid
ExecStart=/usr/bin/sudo /usr/local/sbin/gsad -k /var/lib/gvm/private/CA/clientkey.pem -c /var/lib/gvm/CA/clientcert.pem
Restart=always
TimeoutStopSec=10

[Install]
WantedBy=multi-user.target
Alias=greenbone-security-assistant.service
EOL
sudo -Hiu gvm gvm-manage-certs -a
echo "gvm ALL = NOPASSWD: $(which gsad)" | sudo tee -a /etc/sudoers.d/gvm
sudo systemctl daemon-reload
sudo systemctl enable --now gsad
systemctl --no-pager status gsad
echo "--------------------------------------------------------------------------"
#Creating GVM Scanner
echo "Create GVM Scanner" | tee -a $LOG
sudo -Hiu gvm /usr/local/sbin/gvmd --get-scanners


#Creating GVM Admin User
echo "Creating GVM Admin User" | tee -a $LOG
sudo -Hiu gvm /usr/local/sbin/gvmd --create-user admin --password=Admin

#Set the Feed Import Owner
echo "[31]Set the Feed Import Owner" | tee -a $LOG
echo "Fetching admin user UUID..."
UUID=$(sudo -Hiu gvm /usr/local/sbin/gvmd --get-users --verbose | grep -w admin | awk '{print $2}')
if [[ -z "$UUID" ]]; then
    echo "Admin user UUID not found!"
    exit 1
fi
echo "Admin UUID: $UUID"
echo "Setting admin user UUID to scanner setting..."
sudo -Hiu gvm /usr/local/sbin/gvmd \
  --modify-setting 78eceaec-3385-11ea-b237-28d24461215b \
  --value "$UUID"
echo "--------------------------------------------------------------------------"
#Accessing GVM Web Interface
echo "Accessing GVM Web Interface" | tee -a $LOG
sudo ss -altnp | grep 443
sudo ufw allow 443/tcp

echo "--------------------------------------------------------------------------"
echo "GreenBone Configuration Compelete"