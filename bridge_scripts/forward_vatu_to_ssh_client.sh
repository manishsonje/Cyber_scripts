#!/bin/bash

echo "Make sure you have ssh port forwarding to the ssh client -R 502:127.0.0.1:502"
echo "Make sure that you have routing of localnet enabled sysctl -w net.ipv4.conf.all.route_localnet=1"

sudo iptables -t nat -A PREROUTING -p tcp --dport 502 -s 172.17.17.10 -j DNAT --to-destination 127.0.0.1:502

