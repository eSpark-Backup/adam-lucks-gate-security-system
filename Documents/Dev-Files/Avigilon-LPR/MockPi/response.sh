#!/bin/sh
   
# HTTP_CODE=$(curl --write-out "%{http_code}\n" "http://192.168.1.247:9000/hooks/response" --output output.txt)
# echo $HTTP_CODE 
echo "Entire Payload: $1"
echo "plateNum: $2"
echo "timestamp: $3"

log=log_file.txt
sudo chmod 777 $log
 
# append date to log file
echo $2 >  $log
echo $3 >> $log