# takeover_4gnet.sh (corrected)
#!/bin/bash
#
## Remove old route (optional, if relevant)
sudo ip route del 172.17.0.0/16 2>/dev/null
sudo brctl delif MG_WBR 4G_net
## Ensure interface is up
sudo ip link set 4G_net up
#
## Ensure it's part of the bridge
#if ! brctl show MG_WBR | grep -qw 4G_net; then
#    sudo brctl addif MG_WBR 4G_net
#fi
#
# Assign IP to MG_WBR if required
sudo ifconfig MG_WBR 192.168.1.1 up
