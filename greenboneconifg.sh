#!/bin/bash
set -e
figlet -f slant "GreenBone Configuration"

#Configuring OpenVAS Scanner Redis Data Store
echo "Configuring OpenVAS Scanner Redis Data Store" | tee -a $LOG
sudo ldconfig

LOG=/var/log/greenbone.log
OPENVAS_SCANNER=$(curl -s https://api.github.com/repos/greenbone/openvas-scanner/releases/latest | grep -oP "\"tag_name\": \"\K(.*)(?=\")")
OPENVAS_SCANNER_VERSION="${OPENVAS_SCANNER#v}"
sudo cp /opt/gvm/gvm-source/openvas-scanner-${OPENVAS_SCANNER_VERSION}/config/redis-openvas.conf /etc/redis/
sudo chown redis:redis /etc/redis/redis-openvas.conf
echo "Path to Redis unix socke : $(sudo grep unixsocket /etc/redis/redis-openvas.conf)" | tee -a $LOG
echo "db_address = /run/redis-openvas/redis.sock" | sudo tee /etc/openvas/openvas.conf
echo " Adding GVM user to Redis Group" | tee -a $LOG
sudo usermod -aG redis gvm
#Optimize Redis Performance
echo " Optimizing Redis Performance" | tee -a $LOG
echo "net.core.somaxconn = 1024" | sudo tee -a /etc/sysctl.conf
echo 'vm.overcommit_memory = 1' | sudo tee -a /etc/sysctl.conf
echo "Reloding Systemctl variable" 
sudo sysctl -p

#To avoid creation of latencies and memory usage issues with Redis, disable Linux Kernel’s support for Transparent Huge Pages (THP)
echo "To avoid creation of latencies and memory usage issues with Redis, disable Linux Kernel’s support for Transparent Huge Pages (THP)"
sudo tee /etc/systemd/system/disable_thp.service << 'EOL'
[Unit]
Description=Disable Kernel Support for Transparent Huge Pages (THP)

[Service]
Type=simple
ExecStart=/bin/sh -c "echo 'never' > /sys/kernel/mm/transparent_hugepage/enabled && echo 'never' > /sys/kernel/mm/transparent_hugepage/defrag"

[Install]
WantedBy=multi-user.target
EOL
sudo systemctl daemon-reload
sudo systemctl enable --now disable_thp
sudo systemctl enable --now redis-server@openvas
#Confrim the status of redis server
systemctl status redis-server@openvas
echo "--------------------------------------------------------------------------"
#Configure Mosquitto MQTT Broker for GVM
echo "Configure Mosquitto MQTT Broker for GVM" | tee -a $LOG
echo "mqtt_server_uri = localhost:1883
table_driven_lsc = yes" | sudo tee -a /etc/openvas/openvas.conf
sudo systemctl enable --now mosquitto
systemctl status mosquitto
sudo ss -antpl | grep :1883
echo "--------------------------------------------------------------------------"
#Update GVM Directories Ownership and Permissions
echo "[21]Update GVM Directories Ownership and Permissions" | tee -a $LOG
sudo mkdir -p /var/lib/notus /run/gvmd
sudo chown -R gvm:gvm /var/lib/gvm \
	/var/lib/openvas \
	/var/lib/notus \
	/var/log/gvm \
	/run/gvmd

echo "--------------------------------------------------------------------------"

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