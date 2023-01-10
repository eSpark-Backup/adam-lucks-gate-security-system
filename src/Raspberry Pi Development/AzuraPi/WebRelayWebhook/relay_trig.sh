#!/bin/sh
   
# HTTP_CODE=$(curl --write-out "%{http_code}\n" "http://192.168.1.247:9000/hooks/response" --output output.txt)
# echo $HTTP_CODE 
echo "Entire Payload: $1"
echo "MAC Address: $2"
echo "Relay Status: $3"

# value=$(<pass.txt)
# echo "$value"

sudo chmod 777 $log
 
# append date to log file
if [ "$3" = "true" ]; then
	echo "Calling script"
	python3 relay_trig.py
fi