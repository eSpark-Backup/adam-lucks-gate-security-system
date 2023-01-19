import os
import time
import datetime

RPI_ID       = "10000000e670fa79" #Will need to change
RelayMAC     = "00:0C:C8:03:35:D6" #Will need to change
timestamp    = datetime.datetime.now()

os.system("echo 1 > /sys/class/ionopi/relay/o2")
time.sleep(1)
os.system("echo 0 > /sys/class/ionopi/relay/o2")
f = open('log_file.txt', 'a')
f.write(str(timestamp)+" Relay Trigger Success\n")
f.close()