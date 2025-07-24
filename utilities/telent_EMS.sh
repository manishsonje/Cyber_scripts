#!/bin/bash

# Usage: ./check_open_ports.sh [start_port] [end_port]

START_PORT=${1:-1}    # default start port is 1
END_PORT=${2:-65535}   # default end port is 1024
HOST="172.17.17.10"

echo "Scanning $HOST from port $START_PORT to $END_PORT using telnet..."

for (( port=$START_PORT; port<=$END_PORT; port++ ))
do
  result=$(echo quit | timeout 1 telnet $HOST $port 2>/dev/null)

  if echo "$result" | grep -q "Connected"; then
    echo "Port $port is OPEN"
    read -p "Press Enter to continue scanning..."
  fi
done
