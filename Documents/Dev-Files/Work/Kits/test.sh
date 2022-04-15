!/bin/sh

echo
echo
echo "********* Tests *********"

uptime=`awk '{print int($1)}' /proc/uptime`
echo "Controller uptime $uptime sec"
echo

/root/control.sh hourly

echo
echo "** Contents of Codes Buffer /tmp/accessCodes.buf **"
cat /tmp/accessCodes.buf

echo
/root/control.sh daily

echo
echo "** Testing good code **"
/root/control.sh code 485D8C

echo
echo "** Testing BAD code **"
/root/control.sh code 123456

echo
echo "** Contents of Access Log /tmp/access.log **"
cat /tmp/access.log

echo
echo "** Contents of Offline Buffer /tmp/accessOffline.buf **"
cat /tmp/accessOffline.buf


#echo
#echo " - Reset the m32u4 chip:"
#reset-mcu