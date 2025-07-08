#!/bin/bash
#
sudo ifconfig EMS_MOP down
sudo brctl delif EMS_BR EMS_MOP
sudo ifconfig sw_port2 up 0.0.0.0
#sudo ifconfig EMS_BR 172.17.17.10 up
sudo ip address add 172.17.17.10/24 dev EMS_BR

### routing
#
