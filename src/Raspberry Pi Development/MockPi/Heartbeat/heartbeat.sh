#!/bin/sh
   
# HTTP_CODE=$(curl --write-out "%{http_code}\n" "http://192.168.1.247:9000/hooks/response" --output output.txt)
# echo $HTTP_CODE 

curl --location --request POST 'https://zuul2.zuulsystems.com/api/iono-heartbeat-logs' \
--header 'Content-Type: application/json' \
--data-raw '{
    "connected_pi_mac_address":"F46170099",
    "status":"1"
}'

sleep 30