#!/bin/bash
set -e 
CONTAINERS="containers.txt"
LOG="/var/log/UnistallGreenBone.log"

#This Script will Unistall Greenbone
docker ps -a --format '{{.Names}}' | grep  'greenbone' > $CONTAINERS || true

if [ -s "$CONTAINERS" ]; then
	echo "[Greenbone]{INFO} --> Container 'greenbone' found. Unistalling it..." | tee -a $LOG
	for container in $(cat $CONTAINERS); do

        echo "[Greenbone]{INFO} --> Stopping container: $container" | tee -a "$LOG"
        #docker stop "$container" | tee -a "$LOG"

        echo "[Greenbone]{INFO} --> Removing container: $container" | tee -a "$LOG"
        #docker rm "$container" | tee -a "$LOG"
	done
	echo "[Greenbone]{INFO} --> Greenbone Unistallation Completed" | tee -a $LOG
else
	echo "[Greenbone]{ERROR} --> No Greenbone Installed" | tee -a $LOG
fi
#Removing Container list file
rm -f $CONTAINERS
 