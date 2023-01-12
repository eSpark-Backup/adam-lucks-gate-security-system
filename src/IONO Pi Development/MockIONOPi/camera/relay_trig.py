import os
import time

RPI_ID       = "10000000ac28b34c"
RelayMAC     = "00:0C:C8:03:35:D6"



os.system("curl --request GET 'http://192.168.1.51/state.xml?relay1State=1'")
time.sleep(10)
os.system("curl --request GET 'http://192.168.1.51/state.xml?relay1State=0'")