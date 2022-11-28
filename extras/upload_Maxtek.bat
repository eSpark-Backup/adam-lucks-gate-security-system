@ECHO OFF

taskkill /F /IM putty.exe /T


CALL "C:\Program Files (x86)\WinSCP\WinSCP.exe" /command "option batch abort" "option confirm off" "open scp://root:s5m3g5h9e8@192.168.1.189/ -hostkey=*" "put ""C:\Work\Firmware\control_F46170099_MAXTEK.hex"" /tmp/sketch.hex" "exit"

"C:\Program Files\PuTTY\putty.exe" -ssh root@192.168.1.189 -pw s5m3g5h9e8 -m C:\Work\tmp\putty.upload