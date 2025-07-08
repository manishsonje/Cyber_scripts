#!/bin/bash
#

sudo ifconfig nessus down
sudo ifconfig nessus up 0.0.0.0
sudo ip address add 172.17.17.12/24 dev nessus
sudo ip route add 172.17.0.0/16 via 172.17.17.1 src 172.17.17.12 dev nessus

### routing
#
