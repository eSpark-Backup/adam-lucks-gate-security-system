#!/bin/sh




wgclient="WRT001"
VPN_IP="10.255.0.1"


WG_ENDPOINT="192.53.167.218" # vpn.zuulsystems.com
# Controllers:10.252 ; Routers:10.255


# Configuration parameters
WG_IF="vpn"
WG_PORT="58201"
PingIP="linode.com"

# cameras 11->29 , Arduinos 51->59 , controllers 81 ->89

uci set system.@system[0].hostname=$wgclient
uci commit system
/etc/init.d/system reload


if [ "$1" = "check" ]; then

	echo " ## Checking VPN connection"
	tries=0
	while [[ $tries -lt 5 ]]; do
		if /bin/ping -c 1 $VPN_IP &>/dev/null; then
			echo "[ ok ] ${WG_IF} UP AND RUNNING"
			exit
		fi

		tries=$((tries+1))
		echo " - retrying to ping $VPN_IP : $tries"
		sleep 2
	done


	echo "[FAIL] ${WG_IF} is not running.. attempting restart" >&2
	ifdown ${WG_IF}
    ifup ${WG_IF}
	exit 1
fi





# -o

tries=0
while [[ $tries -lt 5 ]]; do
	if /bin/ping -c 1 $PingIP &>/dev/null; then

		if [ ! -d /tmp/opkg-lists ]; then
			echo " - running opkg update"
			opkg update > /dev/null
			[ "$?" != "0" ] && echo "[ERROR] Unable to run opkg update" && exit 1
		fi

		if [ ! -f /usr/bin/wg ]; then
			echo " - installing Wireguard VPN"
			opkg install wireguard luci-app-wireguard
			mkdir -p /etc/wireguard
		fi

		opkg install usbreset
		break

	fi

	tries=$((tries+1))
	echo " No Internet access - retrying to ping $PingIP : $tries"
	sleep 2

done

if [[ $tries -ge 5 ]]; then
	echo "[ERROR] Unable to connect to the internet"
	exit 1
fi




echo "  -- dropbear"
uci set dropbear.@dropbear[0].PasswordAuth="off"
uci set dropbear.@dropbear[0].RootPasswordAuth="off"
uci commit dropbear
/etc/init.d/dropbear restart






# Wireguard VPN
# https://openwrt.org/docs/guide-user/services/vpn/wireguard/client

cd /etc/wireguard
# Generate keys

echo " - Generating Keys"

if [ ! -f "/etc/dropbear/wgclient.${wgclient}.key" ]; then
	echo "  -- wgclient.${wgclient}.key"
	umask go=
	wg genkey | tee "/etc/dropbear/wgclient.${wgclient}.key" | wg pubkey > wgclient.${wgclient}.pub
fi

if [ ! -f wgserver.vpn.psk -o ! -f wgserver.vpn.pub ]; then
	echo "[ERROR] missing wgserver.vpn.psk or wgserver.vpn.pub" && exit 1
fi



# Client private key
WG_KEY="$(cat /etc/dropbear/wgclient.${wgclient}.key)"

# Pre-shared key
WG_PSK="$(cat wgserver.vpn.psk)"

# Server public key
WG_PUB="$(cat wgserver.vpn.pub)"


echo " - Configuring VPN Client ${wgclient}"



# Configure network
echo "  -- network interface"
uci -q delete network.${WG_IF} &> /dev/null
uci set network.${WG_IF}="interface"
uci set network.${WG_IF}.proto="wireguard"
uci set network.${WG_IF}.private_key="${WG_KEY}"
uci set network.${WG_IF}.metric="35"
uci add_list network.${WG_IF}.addresses="${VPN_IP}/32"


echo "  -- firewall"
uci del_list firewall.wan.network="${WG_IF}" &> /dev/null
uci del_list firewall.lan.network="${WG_IF}" &> /dev/null
uci add_list firewall.lan.network="${WG_IF}" &> /dev/null

uci commit firewall
/etc/init.d/firewall restart &> /dev/null

# Add VPN peers

echo "  -- vpn peer"
uci -q delete network.wgserver &> /dev/null
uci set network.wgserver="wireguard_${WG_IF}"
uci set network.wgserver.public_key="${WG_PUB}"
uci set network.wgserver.preshared_key="${WG_PSK}"
uci set network.wgserver.endpoint_host="${WG_ENDPOINT}"
uci set network.wgserver.endpoint_port="${WG_PORT}"
uci set network.wgserver.route_allowed_ips="1"
uci set network.wgserver.persistent_keepalive="25"

echo "  -- vpn allowed IPs"
uci delete network.wgserver.allowed_ips &> /dev/null

uci add_list network.wgserver.allowed_ips="10.255.255.193/26"


uci commit network
/etc/init.d/network restart > /dev/null


ip route

## https://www.karlrupp.net/en/computer/nat_tutorial
#iptables -t nat -A PREROUTING -s "${VPN_IP%.*}.0/24" -i eth0


## wget -qO - http://192.168.11.12/Login.htm | grep "<title>"
## wget --user=admin --password=aXj22ym8 -qO - http://192.168.11.81 | gzip -cdf |  grep "<title>"
## wget --user=admin --password=aXj22ym8 -qO - http://192.168.11.81/st0.xml | gzip -cdf
