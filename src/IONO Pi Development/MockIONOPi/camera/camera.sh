#!/bin/sh
   
# HTTP_CODE=$(curl --write-out "%{http_code}\n" "http://192.168.1.247:9000/hooks/response" --output output.txt)
timestamp() {
  date +"%T" # current time
}

echo "Entire Payload: $1"
echo "MAC Address: $2"
echo "Relay Status: $3"
 

# append date to log file
if [ "$3" = "true" ]; then
	python zuulcamera_nonLPR.py
fi
