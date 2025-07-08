#!/bin/bash




for i in EMS_BR ECS_BR MG_LBR MG_WBR
do
        sudo ifconfig $i down &>/dev/null
        sudo brctl delbr $i &>/dev/null
done

for i in EMS_MOP ECS_MOP MG_LAN MG_WBR 4G_net MG_WAN
do
        sudo ifconfig $i 0.0.0.0 &>/dev/null
        sudo ifconfig $i down &>/dev/null
done

for i in sw_port1 sw_port2 sw_port3 sw_port6 sw_port7 sw_port8 nessus 
do
        sudo ifconfig $i down &>/dev/null
done

sudo brctl addbr EMS_BR
sudo brctl addif EMS_BR EMS_MOP
sudo brctl addif EMS_BR sw_port2
sudo ifconfig EMS_MOP up
sudo ifconfig sw_port2 up
sudo ifconfig EMS_BR up


sudo brctl addbr ECS_BR
sudo brctl addif ECS_BR ECS_MOP
sudo brctl addif ECS_BR sw_port3
sudo ifconfig ECS_MOP up
sudo ifconfig sw_port3 up
sudo ifconfig ECS_BR up


sudo brctl addbr MG_LBR
sudo brctl addif MG_LBR MG_LAN
sudo brctl addif MG_LBR sw_port1
sudo ifconfig MG_LAN up
sudo ifconfig sw_port1 up
sudo ifconfig MG_LBR up


sudo brctl addbr MG_WBR
sudo brctl addif MG_WBR 4G_net
sudo brctl addif MG_WBR MG_WAN
sudo ifconfig 4G_net up
sudo ifconfig MG_WAN up
sudo ifconfig MG_WBR up


for i in sw_port6 sw_port7 sw_port8 nessus
do
	sudo ifconfig $i 0.0.0.0 up
done
