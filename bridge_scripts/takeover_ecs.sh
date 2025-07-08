#!/bin/bash
#
sudo ifconfig ECS_MOP down
sudo brctl delif ECS_BR ECS_MOP
sudo ifconfig sw_port3 up 0.0.0.0
#sudo ifconfig ECS_BR 172.17.17.20 up
sudo ip address add 172.17.17.20/24 dev ECS_BR

### routing
#
