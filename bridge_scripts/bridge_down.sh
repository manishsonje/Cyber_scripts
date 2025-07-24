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
