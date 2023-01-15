from select import poll, POLLPRI
import time
import os

parameters = {
  "w1_enabled": 1,
  "w1_pulse_width_min": 20,
  "w1_pulse_width_max": 100,
  "w1_pulse_itvl_min":200,
  "w1_pulse_itvl_max":20000
}
param = list(parameters.values())
constant = 65536*36

file = [open("/sys/class/ionopi/wiegand/w1_enabled",'w'), open("/sys/class/ionopi/wiegand/w1_pulse_width_min",'w'), open("/sys/class/ionopi/wiegand/w1_pulse_width_max",'w'),
         open("/sys/class/ionopi/wiegand/w1_pulse_itvl_min",'w'), open("/sys/class/ionopi/wiegand/w1_pulse_itvl_max",'w')]

for i in range(0, len(parameters)):
    file[i].write(str(param[i]))

f = open("/sys/class/ionopi/wiegand/w1_data", "r")

p = poll()
p.register(f.fileno(), POLLPRI)

f.read()
count = 0

while True:
    print("Waiting for card to scan.........")
    p.poll()
    count = count + 1
    #time.sleep(0.5)

    # consume event
    f.seek(0)
    #scanData = format(int(f.read()) , '026b')
    scanData = f.read()
    print(scanData)
    indices = []
    for idx, value in enumerate(scanData):
        if value == " ":
            indices.append(idx)
            
    scanData = scanData[indices[1]+1:]
    w_bits = format(int(scanData), '026b')
    f_code = int(w_bits[1:9], 2)
    card_number = int(w_bits[9:25], 2)
    print("Scan =", count)
    print("Facility Code =", f_code)
    print("Card Number = " , card_number)
    card_number = constant + card_number
    os.system("curl -X GET -k 'http://zuul2.zuulsystems.com/api/scanned-rfid-code/"+str(card_number)+"' -H 'Content-Type: text/plain' -H 'Authorization: Basic RjQ2MTcwMDk5OnM1bTNnNWg5ZTg='")
    os.system("echo 1 > /sys/class/ionopi/relay/o1")
    time.sleep(2)
    os.system("echo 0 > /sys/class/ionopi/relay/o1")
