#!/bin/sh
 
echo "Entire Payload: $1"
echo "MAC Address: $2"
echo "Relay Status: $3"


if [ "$3" = "true" ]; then
	python relay_trig.py
fi