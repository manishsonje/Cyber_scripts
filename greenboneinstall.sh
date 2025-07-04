#!/bin/bash
set -e
figlet -f slant "GreenBone Installation"

LOG="/var/log/greenbone.log"

#Installing Required Build Tools
echo "Installing Required Build Tools" | tee -a $LOG
sudo apt update && sudo apt install -y \
  gcc g++ make bison flex cmake git pkg-config curl \
  libksba-dev libpcap-dev libglib2.0-dev libgpgme-dev \
  nmap libgnutls28-dev uuid-dev libssh-gcrypt-dev \
  libldap2-dev gnutls-bin libmicrohttpd-dev libhiredis-dev \
  zlib1g-dev libxml2-dev libnet-dev libradcli-dev \
  clang-format doxygen gcc-mingw-w64 xml-twig-tools \
  libical-dev perl-base heimdal-dev libpopt-dev \
  libunistring-dev graphviz libsnmp-dev redis-server \
  python3 python3-dev python3-pip python3-setuptools \
  python3-paramiko python3-lxml python3-defusedxml \
  python3-polib xmltoman python3-packaging python3-wrapt \
  python3-cffi python3-psutil python3-redis python3-gnupg \
  python3-paho-mqtt texlive-fonts-recommended texlive-latex-extra \
  xsltproc rsync libpaho-mqtt-dev libbsd-dev libjson-glib-dev \
  libcjson-dev mosquitto krb5-multidev libgcrypt20-dev \
  libcurl4-gnutls-dev gettext --no-install-recommends
echo "--------------------------------------------------------------------------"	
#Installing NodeJS on Ubuntu 24.04
echo "Installing NodeJS on Ubuntu 24.04" | tee -a $LOG

curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | \
sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/node.gpg

echo "deb  https://deb.nodesource.com/node_18.x nodistro main" | sudo tee /etc/apt/sources.list.d/node.list
sudo apt update
sudo apt install nodejs -y
echo "--------------------------------------------------------------------------"
#Install PostgreSQL on Ubuntu 24.04

echo "Install PostgreSQL on Ubuntu 24.04" | tee -a $LOG
echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" | sudo tee /etc/apt/sources.list.d/pgdg.list

wget -qO- http://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/pgdg.gpg

sudo apt update
sudo apt install postgresql postgresql-contrib postgresql-server-dev-all -y
echo "--------------------------------------------------------------------------"
#Creating PostgreSQL User and Database

echo "Creating PostgreSQL User and Database" | tee -a $LOG


# Create PostgreSQL user 'gvm' if not exists
sudo -Hiu postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname='gvm'" | grep -q 1 || \
  sudo -Hiu postgres createuser gvm

# Create PostgreSQL database 'gvmd' owned by 'gvm' if not exists
sudo -Hiu postgres psql -tc "SELECT 1 FROM pg_database WHERE datname='gvmd'" | grep -q 1 || \
  sudo -Hiu postgres createdb -O gvm gvmd

# Create 'dba' role if not exists
sudo -Hiu postgres psql gvmd -tc "SELECT 1 FROM pg_roles WHERE rolname='dba'" | grep -q 1 || \
  sudo -Hiu postgres psql gvmd -c "CREATE ROLE dba WITH SUPERUSER NOINHERIT;"

# Grant 'dba' role to 'gvm' if not already granted
sudo -Hiu postgres psql gvmd -tc \
  "SELECT 1 FROM pg_auth_members WHERE member = (SELECT oid FROM pg_roles WHERE rolname='gvm') AND roleid = (SELECT oid FROM pg_roles WHERE rolname='dba');" | grep -q 1 || \
  sudo -Hiu postgres psql gvmd -c "GRANT dba TO gvm;"
echo "--------------------------------------------------------------------------"
echo "[5]Creating GVM System User" | tee -a $LOG

# Create system user 'gvm' and home directory if not exists
id gvm &>/dev/null || {
  sudo useradd -r -d /opt/gvm -c "GVM User" -s /bin/bash gvm
  sudo mkdir -p /opt/gvm && sudo chown gvm: /opt/gvm
}

# Set sudo permissions
echo "gvm ALL = NOPASSWD: $(which make) install, $(which python3)" | sudo tee /etc/sudoers.d/gvm > /dev/null

# Validate sudoers file
sudo visudo -c -f /etc/sudoers.d/gvm || { echo "[!] Invalid sudoers file for gvm!" | tee -a $LOG; exit 1; }

sudo systemctl restart postgresql
sudo systemctl enable postgresql
systemctl status postgresql
echo "--------------------------------------------------------------------------"	
#Building GVM from Source Code

echo "Building GVM from Source Code" | tee -a $LOG

sudo su - gvm bash -c'
set -e

SRC_DIR="$HOME/gvm-source"
mkdir -p "$SRC_DIR" && cd "$SRC_DIR"

declare -A repos=(
  [gvm-libs]=gvm-libs [gvmd]=gvmd [pg-gvm]=pg-gvm
  [openvas-smb]=openvas-smb [openvas-scanner]=openvas-scanner
  [gsad]=gsad [ospd-openvas]=ospd-openvas
  [notus-scanner]=notus-scanner [gsa]=gsa
)

for name in "${!repos[@]}"; do
  repo="${repos[$name]}"
  version=$(curl -s https://api.github.com/repos/greenbone/$repo/releases/latest | grep -oP "\"tag_name\": \"\K(.*)(?=\")")
  [[ -z $version ]] && echo "[!] Failed: $name" && exit 1
  echo "[+] $name: $version"
  wget -q "https://github.com/greenbone/$repo/archive/refs/tags/${version}.tar.gz" -O "$name.tar.gz"
  tar -xf "$name.tar.gz"
done
echo "[✓] All sources downloaded to $SRC_DIR"
SRC_DIR="$HOME/gvm-source"
declare -A types=(
  [gvm-libs]=cmake [gvmd]=cmake [pg-gvm]=cmake
  [openvas-smb]=cmake [openvas-scanner]=cmake
  [gsad]=cmake [ospd-openvas]=python
  [notus-scanner]=python [gsa]=npm
)
for name in "${!types[@]}"; do
  type="${types[$name]}"
  dir=$(find "$SRC_DIR" -maxdepth 1 -type d -name "${name}-*" | head -n1)
  cd "$dir" || { echo "[!] Missing $name directory"; exit 1; }

  echo "[*] Building $name ($type)"
  case "$type" in
    cmake)
      mkdir -p build && cd build
      cmake .. && make -j$(nproc) && sudo make install
      ;;
    python)
      python3 -m venv venv && source venv/bin/activate && pip install .
      ;;
    npm)
      npm install && npm run build
      ;;
  esac
done

'
[[ -d /usr/local/share/gvm/gsad/web ]] || sudo mkdir -p /usr/local/share/gvm/gsad/web
GSA=$(curl -s https://api.github.com/repos/greenbone/gsa/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
GSA_VERSION="${GSA#v}"
sudo cp -rp /opt/gvm/gvm-source/gsa-${GSA_VERSION}/build/* /usr/local/share/gvm/gsad/web
sudo chown -R gvm: /usr/local/share/gvm/gsad/web
ls -1 /usr/local/share/gvm/gsad/web

echo "----"
OSPD_OPENVAS=$(curl -s https://api.github.com/repos/greenbone/ospd-openvas/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
OSPD_OPENVAS_VERSION="${OSPD_OPENVAS#v}"
sudo cp /opt/gvm/gvm-source/ospd-openvas-${OSPD_OPENVAS_VERSION}/venv/bin/ospd-openvas /usr/local/bin/
sudo cp -r  /opt/gvm/gvm-source/ospd-openvas-${OSPD_OPENVAS_VERSION}/venv/lib/python3.12/* /usr/local/lib/python3.12/

NOTUS_SCANNER=$(curl -s https://api.github.com/repos/greenbone/notus-scanner/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
NOTUS_SCANNER_VERSION="${NOTUS_SCANNER#v}"
sudo cp /opt/gvm/gvm-source/notus-scanner-${NOTUS_SCANNER_VERSION}/venv/bin/* /usr/local/bin/
sudo cp -r /opt/gvm/gvm-source/notus-scanner-${NOTUS_SCANNER_VERSION}/venv/lib/python3.12/site-packages/* /usr/local/lib/python3.12/site-packages/

sudo cp /opt/gvm/gvm-source/greenbone-feed-sync/venv/bin/greenbone-feed-sync /usr/local/bin/
sudo cp -r /opt/gvm/gvm-source/greenbone-feed-sync/venv/lib/python3.12/site-packages/* /usr/local/lib/python3.12/site-packages/

echo "All components built successfully"

echo "--------------------------------------------------------------------------"
# Installing GVM NVTs Feed Synchronization tool
echo "Installing GVM NVTs Feed Synchronization tool" | tee -a $LOG
declare -A tools=(
  ["greenbone-feed-sync"]="GVM NVTs Feed Synchronization tool"
  ["gvm-tools"]="GVM tools"
)

for tool in "${!tools[@]}"; do
  echo "[Installing] ${tools[$tool]}" | tee -a "$LOG"
  
  sudo su - gvm bash -c "
    set -e
    cd ~/gvm-source && mkdir -p $tool && cd $tool
    python3 -m venv venv
    source venv/bin/activate
    pip install $tool
  "
done
echo "--------------------------------------------------------------------------"

echo "GreenBone Installtion complete"