#!/bin/sh
   
# HTTP_CODE=$(curl --write-out "%{http_code}\n" "http://192.168.1.247:9000/hooks/response" --output output.txt)
# echo $HTTP_CODE
echo "Received: $1"
echo "Status: $2"
echo "CameraMAC: $3"

log=log_file.txt
sudo chmod 777 $log
 
# append date to log file
echo $2 >  $log
echo $3 >> $log