#!/bin/bash
set -e 

LOG"/var/log/UnistallNessus.log"

#This Script will Unistall Nessus

if docker ps -a --format '{{.Names}}' | grep -qw "nessus-managed"; then
	echo "[Nessus]{INFO} --> Container 'nessus-managed' found. Unistalling it..." | tee -a $LOG
	docker stop nessus-managed
	docker rm nessus-managed
	echo "[Nessus]{INFO} --> Nessus Unistallation Completed" | tee -a $LOG

else
	echo "[Nessus]{ERROR} --> No Nessus Installed" | tee -a $LOG
fi