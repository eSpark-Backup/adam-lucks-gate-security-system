#!/bin/sh




# /root/init.sh force






if [ "$1" = "ffmpeg" ]; then

		if [ ! -d /mnt/sda1 ]; then
			echo "[ERROR] SD Card not mounted in /mnt/sda1"
			exit 1	
		fi

		if [ ! -d /tmp/opkg-lists ]; then
			echo " - running opkg update"
			opkg update > /dev/null
			[ "$?" != "0" ] && echo "[ERROR] Unable to run opkg update" && exit 1
		fi

				
		echo " - installing ffmpeg package on SD Card"
		opkg --add-dest sd:/mnt/sda1 -d sd install ffmpeg libffmpeg-full > /dev/null
		[ "$?" != "0" ] && echo "[ERROR] Unable to install ffmpeg package" && exit 1



		find /mnt/sda1/usr/lib -xdev -maxdepth 1 \( -type f -o -type l \) -name "*.so*" -exec ln -sf {} /usr/lib \;
		find /mnt/sda1/lib -xdev -maxdepth 1 \( -type f -o -type l \) -name "*.so*" -exec ln -s {} /lib \;
		find /mnt/sda1/usr/bin -xdev -maxdepth 1 -type f -exec ln -s {} /usr/bin \;
		#cp /mnt/sda1/lib/modules/4.14.167/input-core.ko /lib/modules/4.14.167/
		#cp /mnt/sda1/lib/modules/4.14.167/soundcore.ko /lib/modules/4.14.167/
		

		ver=`uname -r`

		cp /mnt/sda1/etc/modules.d/* /etc/modules.d/
		cp /mnt/sda1/lib/modules/$ver/*.ko /lib/modules/$ver/
		ln -s /mnt/sda1/usr/share/alsa/ /usr/share/

		mkdir -p /mnt/sda1/cam

		ffmpeg -version > /dev/null
		[ "$?" != "0" ] && echo "[ERROR] ffmpeg did not execute properly" && exit 1

		ffmpeg -version | head -n 1
		echo "[ ok ] Success installing ffmpeg on SD Card"

		exit 0

# rtsp://192.168.1.10:554/user=admin_password=tlJwpbo6_channel=1_stream=0.sdp?real_stream
# ffmpeg -rtsp_transport tcp -i "rtsp://192.168.1.10:554/user=admin_password=tlJwpbo6_channel=1_stream=0.sdp?real_stream" -frames 1 /mnt/sda1/cam/picture1.jpg
# ffmpeg -ss 2 -i "rtsp://192.168.1.10:554/user=admin_password=tlJwpbo6_channel=1_stream=0.sdp?real_stream--rtp-caching=100" -y -s hd720 -f image2 -qscale 0 -frames 1 /mnt/sda1/cam/picture1.jpg
# ffmpeg -analyzeduration 2147483647 -probesize 2147483647 -ss 2 -i "rtsp://192.168.1.10:554/user=admin_password=tlJwpbo6_channel=1_stream=0.sdp?real_stream--rtp-caching=100" -y -s 1280x720 -f image2 -frames 1 /mnt/sda1/cam/picture1.jpg


# ffmpeg -rtsp_transport tcp -i "rtsp://192.168.1.10:554/user=admin_password=tlJwpbo6_channel=1_stream=0.sdp?real_stream"  -map 0 -y -f image2 -s 1280x720 -b:v 2048000 -r 15 -frames 1 /mnt/sda1/cam/picture1.jpg


# ffmpeg -i "rtsp://192.168.1.10:554/user=admin_password=tlJwpbo6_channel=1_stream=0.sdp?real_stream&videocodec=jpeg"  -y -f image2 -frames 1 /mnt/sda1/cam/picture1.jpg

# ffmpeg -i /mnt/sda1/tmp/test.mkv -y -f image2 -frames 1 /mnt/sda1/cam/picture1.jpg -loglevel debug

 
# https://www.unifore.net/ip-video-surveillance/simple-guide-of-ip-camera-bitrate-setting.html

fi








ifname=`uci get network.lte.ifname 2>/dev/null`
if [ -n "$ifname" -a -f /root/config -a "$1" != "force" ]; then
	echo "Already initiated.. $ifname .. Exiting.."
	exit 0
fi


if [ ! -f /root/config ]; then	
	cp -f /root/config.def /root/config
fi
. /root/config


echo "Init Script - DEBUG:$DEBUG UniqueID:$UniqueID"


echo " - Setting Permissions"
chmod 0777 /root/*.sh
chmod 0777 /www/cgi-bin/api/*



if [ ! -d /tmp/opkg-lists ] && [ ! -f /etc/usb-mode.json -o ! -f /etc/config/mwan3 ]; then	

	if [ ! -f /usr/bin/reset-mcu ]; then
		PingIP="downloads.arduino.cc"
	else 
		PingIP="openwrt.com"
	fi

	tries=0
	while [[ $tries -lt 5 ]]; do
		if /bin/ping -c 1 $PingIP &>/dev/null; then

			echo " - running opkg update"
			opkg update > /dev/null
			[ "$?" != "0" ] && echo "[ERROR] Unable to run opkg update" && exit 1


			echo " - installing critical packages"
			opkg install kmod-usb-net-cdc-ether usb-modeswitch mwan3 socat curl > /dev/null
			[ "$?" != "0" ] && echo "[ERROR] Unable to install critical packages" && exit 1
			#mwan3 start

			echo " - installing storage packages"
			opkg install kmod-fs-f2fs f2fs-tools kmod-usb-storage block-mount coreutils-realpath > /dev/null
			[ "$?" != "0" ] && echo "[ERROR] Unable to install storage packages" && exit 1

			echo " - installing imaging packages"
			opkg install motion > /dev/null

			
			if [ ! -f /usr/bin/reset-mcu  ]; then
				# opkg install usbutils
				#  mkfs.f2fs /dev/sda1
				# block detect | uci import fstab
				# uci set fstab.@mount[-1].enabled='1'
				# uci set fstab.@global[0].check_fs='1'
				# uci commit
				#			else
				opkg install nano luci-app-mwan3 gdisk > /dev/null
			fi
			
			
			if [ "$DEBUG" != "1" ]; then
				echo " - rebooting"
				reboot
			fi
			exit 0
		fi
		
		tries=$((tries+1))
		echo " - retrying to ping $PingIP : $tries"
		sleep 2
		
	done
	echo "[ERROR] Unable to connect to the internet" 
	exit 1	

fi


echo " - uci config"
uci batch << EOF
set network.wan.metric='10'
set network.wan.ipv6='auto'

set network.lte='interface'
set network.lte.ifname='eth1'
set network.lte.proto='dhcp' 
set network.lte.metric='20' 
set network.lte.ipv6=1

set system.ntp.enable_server=1
EOF


if [ -f /usr/bin/reset-mcu  ]; then
	uci set network.lte.ifname='eth2'
	### BAD add_list firewall.@zone[1].network='lte'
fi

 

uci commit
sync
luci-reload

/etc/init.d/firewall restart > /dev/null
/etc/init.d/network restart > /dev/null

