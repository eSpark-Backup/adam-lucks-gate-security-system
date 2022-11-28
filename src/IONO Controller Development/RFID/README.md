Controller Iono Arduino YUN for RFID Readers
======================================================================

## Initial RFID Reader Setup
 - AWID readers require no initial setup, but their range and power can be adjusted by connecting them directly to a laptop using a serial to USB adapter and running AWID Setup software
 - Maxtek readers require some configuration changes by connecting them directly to a laptop using a USB Mini-A cable and running the Maxtek Q series programmer software:

MaxSecure		241818 ON
Get			9 
Wiegand Format 	26bit
Read Interval		1 second
Tag Model		Q-TYPE


## Add the controller to the Zuul Database:
 - in the Zuul admin interface add a new controller ; uniqueId is the serial number "F12345678"
 - copy or make a note of the new *secretKey* hat was generated
 - depending on the reader that will be connected, write with a marker on the label: A for Awid and M for Maxtek
      
## Move the jumpers
 - Unplug the Controller and open it:
 - Use a flat screwdriver, a bit bigger, insert it's tip just a bit above the green connectors, put your thumb on the blue label, and gently pull up the plastic cover
 - Move jumpers from the top right corner J1 and J2 to the BYP position

## Change Settings
 - connect the laptop and the controller to the same router using Ethernet cables
 - use Advanced IP Scanner to find the controller IP address [newIp] 
 - Browse http://[newIp] - pass: arduino
 - set as name the serial number: Yún name = "F12345678"
 - set root password = [*secretKey*YUN]
 - disable WiFi permanently
 - reboot
      
## Upload the Bash scripts
 - from firmware.zip copy the files inside /root to the controller
 - connect to scp://root:[*secretKey*YUN]@[newIp]
 - copy firmware.zip/root/control.sh to /root
 - test the script:
> chmod 0750 /root/*.sh
> /root/control.sh allcodes
> reset-mcu && rm /tmp/access.log && rm /tmp/*.buf

## Create Cron jobs
 - browse to http://[newIp]/luci/admin/system/crontab
 - add in System > Scheduled Tasks
30 4 * * * /root/control.sh daily &> /tmp/control.daily.out
20 */1 * * * /root/control.sh hourly &> /tmp/control.hourly.out
@reboot /root/control.sh reboot &> /tmp/control.reboot.out
 - click [Submit] ; Manually restart the cron service if the crontab file was empty before editing :
 - go to System > Startup – CRON and click [Restart] 


## Compile the firmware
 - extract the firmware source code from firmware.zip/src/control
 - edit Control.ino with Arduino IDE and set
#define UniqueID "F12345678"	    	// The controller Serial Number, same as hostname
#define SecretKey "*secretKey*"	// The controller SecretKey
#define READER_TYPE 3 			// 1=default 2=AWID 3=Maxtek

 - Click Sketch > Export compiled binarry
 - Rename  Control.ino.with_bootloader.hex to control_F12345678_MAXTEK.hex
 - Upload the firmware to the controller by browsing to http://[newIp]
 - After the reboot you should hear the relays clicking and in /tmp there will be cache and log files
