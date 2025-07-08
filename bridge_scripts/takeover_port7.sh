#!/bin/bash
#

sudo ifconfig sw_port7 down
sudo ifconfig sw_port7 up 0.0.0.0
sudo ip address add 172.17.19.2/24 dev sw_port7
sudo ip route replace 172.17.0.0/16 via 172.17.19.1 src 172.17.19.2 dev sw_port7

### routing
#
