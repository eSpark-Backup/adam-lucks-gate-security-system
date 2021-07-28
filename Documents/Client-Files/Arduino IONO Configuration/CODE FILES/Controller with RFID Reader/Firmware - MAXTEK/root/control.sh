#!/bin/sh


##############################

## DEBUG=1
CODESBUF=/tmp/accessCodes.buf
LOGF=/tmp/access.log
OFFLINEBUF=/tmp/accessOffline.buf

uptime=`awk '{print int($1)}' /proc/uptime`



if [ "$1" == 'daily' ]; then
	echo "** Daily Tasks **"
	###########################################################
	touch $LOGF

	if [ "$DEBUG" != "1" ] && [ "$uptime" -gt 3600 ]; then
		echo " - Sleeping 70 sec"
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

	if [ -f /tmp/bufAll.tmp ]; then
		## if offline for the last hour, reset mcu & reboot
		
		if [ -f /tmp/offline.tmp ] && [ "$uptime" -gt 3600 ]; then
			echo " - rebooting"
			rm -f /tmp/offline.tmp
			reset-mcu
			reboot
		else
			touch /tmp/offline.tmp
		fi		
		exit 1
	else 
		rm -f /tmp/offline.tmp
	fi
 
	exit 0
fi


if [ "$1" == 'reboot' ]; then
	echo "** Reboot Tasks **"
	###########################################################

	ifconfig wlan0 up
	 
	exit 0
fi






expectedLine=${2//[^[:alnum:]]/}
apiUrl=${3//[[:cntrl:]\#&;\`|*?~<>^()\[\]\{\}\$\\]/}


outA=/tmp/control.all.out
outC=/tmp/control.code.out


if [ -z "$expectedLine" ] || [ -z "$apiUrl" ]; then
	echo "Nothing to do !" 
	touch $LOGF
	exit 0
fi






if [ "$1" == 'allcodes' ]; then
	###########################################################

	touch $CODESBUF
	touch $OFFLINEBUF
	echo "" > $outA

	status=`curl --connect-timeout 5 --max-time 60 --basic --silent --retry 2 --retry-delay 10 --retry-max-time 60 -H "Content-Type: text/plain" --data-binary "@$OFFLINEBUF" --output /tmp/bufAll.tmp $apiUrl`
	if [ "$status" = "200" ] && [ -s /tmp/bufAll.tmp ]; then
		firstLine=`head -n 1 /tmp/bufAll.tmp`
		firstLine=${firstLine//[^[:alnum:]]/}		
		echo "Checking first line: $firstLine <> $expectedLine" >> $outA
		if [ "$firstLine" = "$expectedLine" ]; then
			echo " - Downloading new RFID Codes to $CODESBUF" >> $outA
			tail +2 /tmp/bufAll.tmp > $CODESBUF
			rm -f /tmp/bufAll.tmp 	
			echo "" > $OFFLINEBUF	
		else 
			echo "[ERROR] : First line of response $firstLine does not match the expectedLine"  >> $outA
			exit 1
		fi
	else
		echo "[ERROR] : Unable to download RFID Codes! $status"  >> $outA 
		exit 1
	fi 
fi



## /root/control.sh code "code1"
if [ "$1" == 'code' ]; then

	code=${4//[^[:alnum:]]/}
	###########################################################

	
	echo "" > $outC

	if [ -n "$code" ]; then

		TIMESTAMP=`date "+%Y-%m-%d %H:%M:%S"`
		echo -n "[$TIMESTAMP] $code " >> $LOGF


		allowedRemote=""
		allowedLocal=""
		status=`curl --connect-timeout 3 --max-time 6 --basic --silent --retry 1 --retry-delay 1 --retry-max-time 6 --output /tmp/bufCode.tmp $apiUrl$code`

		firstLine=`head -n 1 /tmp/bufCode.tmp`
		firstLine=${firstLine//[^[:alnum:]]/}

		echo "Checking first line: $firstLine <> $expectedLine" >> $outC
		if [ "$status" = "200" ] && [ "$firstLine" = "$expectedLine" ]; then
			allowedRemote=1
			rm -f /tmp/bufCode.tmp 	
		fi
		
		grep -wqs "$code" $CODESBUF && allowedLocal=1

		echo "** Checking code $code; remote:$allowedRemote ($status) local:$allowedLocal **" >> $outC

		if [ -n "$allowedRemote" ]; then
			echo " - access allowed by remote server" >> $outC
			if [ -z "$allowedLocal" ]; then
				echo " - adding code to the local cache" >> $outC
				echo "$code" >> $CODESBUF
			fi
			echo "OK" >> $LOGF 
			exit 0
		else
			if [ -n "$allowedLocal" ]; then
				if [ "$status" = "403" ]; then
					echo " - access was revoked remotelly"	 >> $outC
					echo " - removing code from Offline bufffer " >> $outC
					# sed -i "/^4742540$/d" /tmp/accessCodes.buf
					sed -i "/^$code$/d" $CODESBUF
				else
					echo " - access allowed by local cache"	 >> $outC			
					echo " - adding code to the Offline bufffer " >> $outC
					echo "[$TIMESTAMP] $code" >> $OFFLINEBUF
					echo "ok" >> $LOGF
					exit 0								
				fi
			fi
		fi
		echo " - access denied !" >> $outC
		echo "Denied" >> $LOGF

	else 
		echo "[ERROR] : invalid code!" >> $outC
	fi
 
	exit 1
fi





## If up for more than 1 hour
#@reboot [ `awk '{print int($1)}' /proc/uptime` -gt 3600 ] && 

## reset the m32u4 chip
#@reboot sleep 70 && reset-mcu