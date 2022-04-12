#!/bin/sh
   
HTTP_CODE=$(curl --write-out "%{http_code}\n" "http://192.168.1.247:9000/hooks/response" --output output.txt)
echo $HTTP_CODE 
#log=log_file.txt
#sudo chmod 777 log_file.txt
#printf "Log File - " > $log
 
# append date to log file
#date >> $log
 
#x=$(( 3 + 1 ))
# append some data to log file
#echo value of x is $x >> $log
