#!/bin/bash
#

sudo ifconfig sw_port8 down
sudo ifconfig sw_port8 up 0.0.0.0
sudo ip address add 172.17.20.2/24 dev sw_port8
sudo ip route replace 172.17.0.0/16 via 172.17.20.1 src 172.17.20.2 dev sw_port8

### routing
#
