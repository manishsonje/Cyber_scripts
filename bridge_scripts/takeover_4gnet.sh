#!/bin/bash

sudo ip route del 172.17.0.0/16
sudo brctl delif MG_WBR 4G_net
sudo ifconfig MG_WBR 192.168.1.1

