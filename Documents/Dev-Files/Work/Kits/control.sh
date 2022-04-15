#!/bin/sh

## Config

UniqueID="F46170006"	# The controller Serial Number, same as hostname
SecretKey="c6a6v5s9g8"		# The controller SecretKey
RFIDSURL="https://dev.zuulsystems.com/api/get_all_rf_code"
RFIDURL="https://dev.zuulsystems.com/api/scanned_rf_code/"





##############################

DEBUG=1
CODESBUF=/tmp/accessCodes.buf
LOGF=/tmp/access.log
OFFLINEBUF=/tmp/accessOffline.buf

uptime=`awk '{print int($1)}' /proc/uptime`
userpass="$UniqueID:$SecretKey"



if [ "$1" == 'daily' ]; then
	echo "** Daily Tasks **"
	###########################################################
	touch $LOGF

	if [ "$DEBUG" != "1" ] && [ "$uptime" -gt 3600 ]; then
		echo " - Sleepng 70 sec"
		sleep 70 
		touch /etc/banner
		echo " - Reseting the m32u4 chip and rebooting"
		reset-mcu
		reboot
	else 
		echo " - Up for less than one hour!"
	fi

	lines=`wc -l $LOGF | awk '{print int($1)}'`
	if [ "$lines" -gt 5000 ]; then
		echo " - Trimming log file $LOGF ($lines)"
		tail -n 5000 $LOGF > $LOGF.tmp
		cat $LOGF.tmp > $LOGF
		rm -f $LOGF.tmp
	fi

	lines=`wc -l $OFFLINEBUF | awk '{print int($1)}'`
	if [ "$lines" -gt 5000 ]; then
		echo " - Trimming buffer file $OFFLINEBUF ($lines)"
		tail -n 5000 $OFFLINEBUF > $OFFLINEBUF.tmp
		cat $OFFLINEBUF.tmp > $OFFLINEBUF
		rm -f $OFFLINEBUF.tmp
	fi


	exit 0

fi

if [ "$1" == 'hourly' ]; then
	echo "** Hourly Tasks **"
	###########################################################

	## If up for more than one hour, kill the wifi
	if [ "$DEBUG" != "1" ] && [ "$uptime" -gt 3600 ]; then
		echo " - Turning wifi off"
		ifconfig wlan0 down
	fi

	touch $CODESBUF
	touch $OFFLINEBUF

	status=`curl --connect-timeout 5 --max-time 60 --basic --silent --user "$userpass" --retry 2 --retry-delay 10 --retry-max-time 60 -H "Content-Type: text/plain" --data-binary "@$OFFLINEBUF" --output /tmp/bufh.tmp  -w "%{http_code}" $RFIDSURL`
	if [ "$status" = "200" ] && [ -s /tmp/bufh.tmp ]; then
		firstLine=`head -n 1 /tmp/bufh.tmp`
		firstLine=${firstLine//[^[:alnum:]]/}
		if [ "$firstLine" = "$UniqueID" ]; then
			echo " - Downloading new RFID Codes to $CODESBUF"
			tail +2 /tmp/bufh.tmp > $CODESBUF
			rm -f /tmp/bufh.tmp 	
			echo "" > $OFFLINEBUF	
		else 
			echo "[ERROR] : First line of response $firstLine does not match the UniqueID" >&2 && exit 1
		fi
	else
		## Todo: if offline for the last hour, reset mcu & reboot
		echo "[ERROR] : Unable to download RFID Codes! $status" >&2
		if [ -f /tmp/offline.tmp ] && [ "$uptime" -gt 3600 ]; then
			echo " - rebooting"
			rm -f /tmp/offline.tmp
			reset-mcu
			reboot
		else
			touch /tmp/offline.tmp
		fi		
		exit 1
	fi
 
	exit 0
fi



if [ "$1" == 'reboot' ]; then
	echo "** Reboot Tasks **"
	###########################################################

	ifconfig wlan0 up
	 
	exit 0
fi


## /root/control.sh code "code1"
if [ "$1" == 'code' ]; then

	code=${2//[^[:alnum:]]/}
	###########################################################

	if [ -n "$code" ]; then

		TIMESTAMP=`date "+%Y-%m-%d %H:%M:%S"`
		echo -n "[$TIMESTAMP] $code " >> $LOGF


		allowedRemote=""
		allowedLocal=""
		status=`curl --connect-timeout 3 --max-time 6 --basic --silent --user "$userpass" --retry 1 --retry-delay 1 --retry-max-time 6 --output /tmp/bufc.tmp -w "%{http_code}" $RFIDURL$code`

		firstLine=`head -n 1 /tmp/bufc.tmp`
		firstLine=${firstLine//[^[:alnum:]]/}
		if [ "$status" = "200" ] && [ "$firstLine" = "$UniqueID" ]; then
			allowedRemote=1
			rm -f /tmp/bufc.tmp 	
		fi
		
		grep -wqs "$code" $CODESBUF && allowedLocal=1

		echo "** Checking code $code; remote:$allowedRemote ($status) local:$allowedLocal **"

		if [ -n "$allowedRemote" ]; then
			echo " - access allowed by remote server"
			if [ -z "$allowedLocal" ]; then
				echo " - adding code to the local cache"
				echo "$code" >> $CODESBUF
			fi
			echo "OK" >> $LOGF 
			exit 0
		else
			if [ -n "$allowedLocal" ] && [ "$status" != "403" ]; then
				echo " - access allowed by local cache"				
				echo " - adding code to the Offline access log bufffer "
				echo "[$TIMESTAMP] $code" >> $OFFLINEBUF
				echo "ok" >> $LOGF
				exit 0				
			fi
		fi
		echo " - access denied !"
		echo "Denied" >> $LOGF

	else 
		echo "[ERROR] : invalid code!" >&2
	fi
 
	exit 1
fi







## If up for more than 1 hour
#@reboot [ `awk '{print int($1)}' /proc/uptime` -gt 3600 ] && 

## reset the m32u4 chip
#@reboot sleep 70 && reset-mcu