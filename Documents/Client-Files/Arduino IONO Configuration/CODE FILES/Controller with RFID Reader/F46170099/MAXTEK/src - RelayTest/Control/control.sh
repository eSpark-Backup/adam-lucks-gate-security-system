#!/bin/sh



if [ ! -f /root/config ]; then	
	cp -f /root/config.def /root/config
fi
. /root/config



#ApiRfAllCodes="https://dev.zuulsystems.com/api/get_all_rf_code"
#ApiRfCode="https://dev.zuulsystems.com/api/scanned_rf_code/"

#ApiRfAllCodes="http://192.168.1.200/rfids.php"
#ApiRfCode="http://192.168.1.200/rfid.php?code="


ApiTokens="https://app.zuulsystems.com/api/Controller/getAccessTokens"
ApiRfAllCodes="https://app.zuulsystems.com/api/get_all_rf_code"
ApiRfCode="https://dev.zuulsystems.com/api/scanned_rf_code/"
ApiQrAllCodes="https://app.zuulsystems.com/api"
ApiQrCode="https://dev.zuulsystems.com/api/Controller/validateQrCode/"



##############################



uptime=`awk '{print int($1)}' /proc/uptime`
userpass="$UniqueID:$SecretKey"
UniqueID=${UniqueID//[^[:alnum:]]/}

# For now a single token is accepted and is saved in /etc/httpd.conf
TOKENSBUF=/tmp/tokens.buf

RfLogF=/tmp/access_rf.log
RfCodesBuf=/tmp/codes_rf.buf
RfOfflineBuf=/tmp/offline_rf.buf

QrLogF=/tmp/access_qr.log
QrCodesBuf=/tmp/codes_qr.buf
QrOfflineBuf=/tmp/offline_qr.buf

outA=/tmp/control.allcodes.out
outRfC=/tmp/control.rfcode.out
outQrC=/tmp/control.qrcode.out


if [ "$1" == 'daily' ]; then
	echo "** Daily Tasks **"
	###########################################################
	touch $RfLogF
	touch $QrLogF

	if [ "$DEBUG" != "1" ] && [ "$uptime" -gt 3600 ]; then
		echo " - Sleeping 70 sec"
		sleep 70 
		touch /etc/banner
		echo " - rebooting"
		reboot
	else 
		echo " - Up for less than one hour!"
	fi

	lines=`wc -l $RfLogF | awk '{print int($1)}'`
	if [ "$lines" -gt 5000 ]; then
		echo " - Trimming RF log file $RfLogF ($lines)"
		tail -n 5000 $RfLogF > $RfLogF.tmp
		cat $RfLogF.tmp > $RfLogF
		rm -f $RfLogF.tmp
	fi

	lines=`wc -l $RfOfflineBuf | awk '{print int($1)}'`
	if [ "$lines" -gt 5000 ]; then
		echo " - Trimming RF buffer file $RfOfflineBuf ($lines)"
		tail -n 5000 $RfOfflineBuf > $RfOfflineBuf.tmp
		cat $RfOfflineBuf.tmp > $RfOfflineBuf
		rm -f $RfOfflineBuf.tmp
	fi

	lines=`wc -l $QrLogF | awk '{print int($1)}'`
	if [ "$lines" -gt 5000 ]; then
		echo " - Trimming QR log file $QrLogF ($lines)"
		tail -n 5000 $QrLogF > $QrLogF.tmp
		cat $QrLogF.tmp > $QrLogF
		rm -f $QrLogF.tmp
	fi

	lines=`wc -l $QrOfflineBuf | awk '{print int($1)}'`
	if [ "$lines" -gt 5000 ]; then
		echo " - Trimming QR buffer file $QrOfflineBuf ($lines)"
		tail -n 5000 $QrOfflineBuf > $QrOfflineBuf.tmp
		cat $QrOfflineBuf.tmp > $QrOfflineBuf
		rm -f $QrOfflineBuf.tmp
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
			#reset-mcu
			reboot
		else
			touch /tmp/offline.tmp
		fi		
		exit 1
	else 
		rm -f /tmp/offline.tmp
	fi


	if [ ! -f $outA ] && [ -f /usr/bin/reset-mcu ]; then
		echo " - reseting mcu"
		reset-mcu
	fi


fi



if [ "$1" == 'hourly' ] || [ "$1" == 'allcodes' ]; then
	ec=0

	if [ "$1" == 'allcodes' ]; then
		echo "" > $outA
		touch $RfLogF
		touch $QrLogF
	fi


	##  --data-binary "@/root/photo.jpg"
	status=`curl --connect-timeout 5 --max-time 60 --basic --silent --user "$userpass" --retry 2 --retry-delay 10 --retry-max-time 60 -H "Content-Type: text/plain" --output /tmp/bufToken.tmp -w "%{http_code}" $ApiTokens`
	if [ "$status" = "200" ] && [ -s /tmp/bufToken.tmp ]; then
		firstLine=`head -n 1 /tmp/bufToken.tmp`
		firstLine=${firstLine//[^[:alnum:]]/}	
		echo "Checking first line: $firstLine <> $UniqueID"
		if [ "$firstLine" = "$UniqueID" ]; then
			secondLine=`head -n 2 /tmp/bufToken.tmp | tail -n 1`
			secondLine=${secondLine//[^[:alnum:]]/}	
			rm -f /tmp/bufToken.tmp 	
			echo " - received valid access token for $firstLine"				
			if [ "$1" == 'allcodes' ]; then
				echo " - received valid access token for $firstLine" >> $outA
			fi
			authStr=$(uhttpd -m "$secondLine")
			authStr="/cgi-bin/api/:$firstLine:$authStr"
			echo "$authStr - $secondLine" > $TOKENSBUF
			cmp1=`head -n 1 /etc/httpd.conf`	
			cmp1=${cmp1//[^[:alnum:]]/}		
			cmp2=${authStr//[^[:alnum:]]/}		
			if [ "$cmp1" != "$cmp2" ]; then					
				echo " - saving new access token to /etc/httpd.conf"				
				echo "$authStr" > /etc/httpd.conf
				/etc/init.d/uhttpd restart
				echo "$UniqueID" > /www/serial.txt
			fi
		else 
			echo "[ERROR] : First line of response $firstLine does not match the UniqueID"  >&2
			ec=2
		fi
	else
		echo "[ERROR] : Unable to download Access Tokens! $status" >&2
		ec=1
	fi 


	touch $RfCodesBuf
	touch $RfOfflineBuf

	status=`curl --connect-timeout 5 --max-time 60 --basic --silent --user "$userpass" --retry 2 --retry-delay 10 --retry-max-time 60 -H "Content-Type: text/plain" --data-binary "@$RfOfflineBuf" --output /tmp/bufAll.tmp -w "%{http_code}" $ApiRfAllCodes`
	if [ "$status" = "200" ] && [ -s /tmp/bufAll.tmp ]; then
		firstLine=`head -n 1 /tmp/bufAll.tmp`
		firstLine=${firstLine//[^[:alnum:]]/}		
		echo "Checking first line: $firstLine <> $UniqueID"
		if [ "$firstLine" = "$UniqueID" ]; then
			echo " - Downloading new RFID Codes to $RfCodesBuf"
			if [ "$1" == 'allcodes' ]; then
				echo " - Received new RFID Codes, saving to $RfCodesBuf" >> $outA
			fi
			tail +2 /tmp/bufAll.tmp > $RfCodesBuf
			rm -f /tmp/bufAll.tmp 	
			echo "" > $RfOfflineBuf	
		else 
			echo "[ERROR] : First line of response $firstLine does not match the UniqueID" >&2 
			ec=2
		fi
	else
		echo "[ERROR] : Unable to download RFID Codes! $status" >&2 
		ec=1
	fi 



	if [ "$ec" != "0" ] && [ "$1" == 'allcodes' ]; then
		echo "[ERROR] : an error occured in allcodes; status: $ec" >> $outA
	fi 
	exit $ec

fi




if [ "$1" == 'reboot' ]; then
	echo "** Reboot Tasks **"
	###########################################################

	ifconfig wlan0 up
	echo " - Creating Temporary Directories"
	mkdir -p /tmp/listener/log
	mkdir -p /tmp/listener/run

	if [ -f /usr/bin/reset-mcu ]; then
		echo " - Reseting the m32u4 chip"
		reset-mcu
	fi
	 
	exit 0
fi





## /root/control.sh rfcode "code1"
if [ "$1" == 'rfcode' ] || [ "$1" == 'code' ]; then

	code=${4//[^[:alnum:]]/}
	if [ -z "$code" ]; then		
		code=${2//[^[:alnum:]]/}
	fi
	###########################################################

	
	echo "" > $outRfC

	if [ -n "$code" ]; then

		TIMESTAMP=`date "+%Y-%m-%d %H:%M:%S"`
		echo -n "[$TIMESTAMP] $code " >> $RfLogF


		allowedRemote=""
		allowedLocal=""
		status=`curl --connect-timeout 5 --max-time 8 --basic --silent --user "$userpass" --retry 2 --retry-delay 1 --retry-max-time 6 --output /tmp/bufRfCode.tmp -w "%{http_code}" $ApiRfCode$code`

		firstLine=`head -n 1 /tmp/bufRfCode.tmp`
		firstLine=${firstLine//[^[:alnum:]]/}

		echo "Checking first line: $firstLine <> $UniqueID" >> $outRfC
		if [ "$status" = "200" ] && [ "$firstLine" = "$UniqueID" ]; then
			allowedRemote=1
			rm -f /tmp/bufRfCode.tmp 	
		fi
		
		grep -wqs "$code" $RfCodesBuf && allowedLocal=1

		echo "** Checking code $code; remote:$allowedRemote ($status) local:$allowedLocal **" >> $outRfC

		if [ -n "$allowedRemote" ]; then
			echo " - access allowed by remote server" >> $outRfC
			if [ -z "$allowedLocal" ]; then
				echo " - adding code to the local cache" >> $outRfC
				echo "$code" >> $RfCodesBuf
			fi
			echo "OK" >> $RfLogF 
			exit 0
		else
			if [ -n "$allowedLocal" ]; then
				if [ "$status" = "403" ]; then
					echo " - access was revoked remotelly"	 >> $outRfC
					echo " - removing code from Offline bufffer " >> $outRfC
					# sed -i "/^4742540$/d" /tmp/accessCodes.buf
					sed -i "/^$code$/d" $RfCodesBuf
				else
					echo " - access allowed by local cache"	 >> $outRfC			
					echo " - adding code to the Offline bufffer " >> $outRfC
					echo "[$TIMESTAMP] $code" >> $RfOfflineBuf
					echo "ok" >> $RfLogF
					exit 0								
				fi
			fi
		fi
		echo " - access denied !" >> $outRfC
		echo "Denied" >> $RfLogF

	else 
		echo "[ERROR] : invalid code!" >> $outRfC
	fi
 
	exit 1
fi








## /root/control.sh qrcode "code1"
if [ "$1" == 'qrcode' ] ; then

	code=${2//[^[:alnum:]]/}
	ScannerId=${3//[^[:digit:]]/}
	###########################################################
	
	echo "" > $outQrC

	if [ -n "$code" ]; then

		TIMESTAMP=`date "+%Y-%m-%d %H:%M:%S"`
		echo -n "[$TIMESTAMP] $code " >> $QrLogF


		allowedRemote=""
		allowedLocal=""
		status=`curl --connect-timeout 5 --max-time 8 --basic --silent --user "$userpass" --retry 2 --retry-delay 1 --retry-max-time 6 --output /tmp/bufQrCode.tmp -w "%{http_code}" $ApiQrCode$code`

		firstLine=`head -n 1 /tmp/bufQrCode.tmp`
		firstLine=${firstLine//[^[:alnum:]]/}

		echo "Checking first line: $firstLine <> $UniqueID" >> $outQrC
		if [ "$status" = "200" ] && [ "$firstLine" = "$UniqueID" ]; then
			allowedRemote=1
			rm -f /tmp/bufQrCode.tmp 	
		fi
		
		grep -wqs "$code" $QrCodesBuf && allowedLocal=1

		echo "** Checking code $code; remote:$allowedRemote ($status) local:$allowedLocal **" >> $outQrC

		if [ -n "$allowedRemote" ]; then
			echo " - access allowed by remote server" >> $outQrC
			if [ -z "$allowedLocal" ]; then
				echo " - adding code to the local cache" >> $outQrC
				echo "$code" >> $QrCodesBuf
			fi
			echo "OK" >> $QrLogF 
			exit 0
		else
			if [ -n "$allowedLocal" ]; then
				if [ "$status" = "403" ]; then
					echo " - access was revoked remotelly"	 >> $outQrC
					echo " - removing code from Offline bufffer " >> $outQrC
					# sed -i "/^4742540$/d" /tmp/accessCodes.buf
					sed -i "/^$code$/d" $QrCodesBuf
				else
					echo " - access allowed by local cache"	 >> $outQrC			
					echo " - adding code to the Offline bufffer " >> $outQrC
					echo "[$TIMESTAMP] $code" >> $QrOfflineBuf
					echo "ok" >> $QrLogF
					exit 0								
				fi
			fi
		fi
		echo " - access denied !" >> $outQrC
		echo "Denied" >> $QrLogF

	else 
		echo "[ERROR] : invalid code!" >> $outQrC
	fi
 
	exit 1
fi








## If up for more than 1 hour
#@reboot [ `awk '{print int($1)}' /proc/uptime` -gt 3600 ] && 

## reset the m32u4 chip
#@reboot sleep 70 && reset-mcu