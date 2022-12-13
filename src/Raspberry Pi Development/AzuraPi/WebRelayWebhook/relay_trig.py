import os
import time

RPI_ID       = "100000002af993d7"
RelayMAC     = "00:0C:C8:06:14:BA"



os.system("curl --request GET 'http://192.168.2.2/state.xml?relay1State=1'")
time.sleep(2)
os.system("curl --request GET 'http://192.168.2.2/state.xml?relay1State=0'")