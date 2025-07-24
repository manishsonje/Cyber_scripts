#!/bin/sh

unit="CCU6"
a_id="110AC01"
ack="acknowledge"
cut="cutot"
val=1
host="172.17.17.20"
port=8883
usr="AMS"
pasd="enquq.ewiwy.bovay.ohyfp"
tpc="public/write/alarm"

while :
do
	#Acknowledge part
	ack_msg="#$(echo $unit|radamsa)/$(echo $a_id|radamsa)/$(echo $ack|radamsa)/$(echo $val|radamsa)"
	echo $ack_msg
	#Publish Acknowledgement
	mosquitto_pub -h $host -p $port -u $usr -P $pasd -t $tpc -m "$ack_msg"  --cafile /home/vagrant/CA.crt  -d -q 1
	
	#Cutout part
	cut_msg="#$(echo $unit|radamsa)/$(echo $a_id|radamsa)/$(echo $cut|radamsa)/$(echo $val|radamsa)"
	echo $cut_msg
	#Publish Acknowledgement
	mosquitto_pub -h $host -p $port -u $usr -P $pasd -t $tpc -m "$cut_msg"  --cafile /home/vagrant/CA.crt  -d -q 1
	
done
