#!/bin/bash
#

sudo ifconfig MG_WAN down
sudo ifconfig MG_WAN up 0.0.0.0
sudo ip address add 192.168.1.2/24 dev MG_WAN
#sudo ip route replace 172.17.0.0/16 via 172.17.19.1 src 172.17.19.2 dev sw_port7

### routing
#
