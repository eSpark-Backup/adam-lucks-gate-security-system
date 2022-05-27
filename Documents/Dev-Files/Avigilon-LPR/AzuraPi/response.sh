#!/bin/sh
   
# HTTP_CODE=$(curl --write-out "%{http_code}\n" "http://192.168.1.247:9000/hooks/response" --output output.txt)
# echo $HTTP_CODE 
echo "Entire Payload: $1"
echo "Type: $2"
echo "plateNum: $3"
echo "timestamp: $4"

log=plate_info.txt
sudo chmod 777 $log
 
# append date to log file
if [ "$2" = "DEVICE_LPR_PLATE_UPDATE" ]; then
	echo $3 >  $log
	echo $4 >> $log
fi