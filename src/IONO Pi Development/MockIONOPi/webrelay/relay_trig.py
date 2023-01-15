import os
import time

RPI_ID       = "10000000ac28b34c" #Will need to change
RelayMAC     = "00:0C:C8:03:35:D6" #Will need to change


os.system("echo 1 > /sys/class/ionopi/relay/o2")
time.sleep(1)
os.system("echo 0 > /sys/class/ionopi/relay/o2")