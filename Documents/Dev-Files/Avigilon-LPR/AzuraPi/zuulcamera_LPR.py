import os
import json
import time
import locale
import pyrebase
from time import sleep
from datetime import datetime

UserUID      = "e2ld9eRaxPODUrVsfHB937cB1ok2"
RPI_ID       = "100000002af993d7"
imagePath    = "/home/pi/Pictures/"
ImageBaseURL = "https://firebasestorage.googleapis.com/v0/b/zuul-master.appspot.com/o/images%2F"
ImageAuxURL  = "?alt=media&token="
imageformat  = ".jpg"
zoomfactor   = "scale=4*iw:-1, crop=iw/4:ih/4:x=3200:y=2500"
cameraMAC    = "00:18:85:3D:3D:90"

config = {
  "apiKey": "AIzaSyBMJa73RYD3-HOwR9ndGWS3SxH9mp4qkJA",
  "authDomain": "zuul-master.firebaseapp.com",
  "databaseURL": "https://zuul-master-404bb.firebaseio.com",
  "storageBucket": "zuul-master.appspot.com"
}

firebase = pyrebase.initialize_app(config)
auth = firebase.auth()
user = auth.sign_in_with_email_and_password("100000002af993d7@email.com", "82z$WYK,rD$<P($e")
db = firebase.database()
st = firebase.storage();


try:
	while True:
    f = open('log_file.txt', 'r+')
    content = f.readline()

		if "true" in str(content).lower():

      imageID = int(time.time())
      timestamp = datetime.utcfromtimestamp(imageID)
      imageID = str(imageID)
      print(timestamp)

			os.system("ffmpeg -rtsp_transport tcp -i rtsp://admin:myzuulsystem1@192.168.2.212/defaultSecondary?streamType=u -f image2 -loglevel quiet -y /home/pi/Pictures/capture.jpg")
			os.system("ffmpeg -i /home/pi/Pictures/capture.jpg -vf 'crop=iw/2:ih/2' -loglevel quiet "+imagePath+imageID+imageformat)

			f = open("plate_info.txt", "r")
			plateNum = f.readline()
			f.close()

			user = auth.refresh(user['refreshToken'])
			st_response = st.child("images/"+imageID+imageformat).put(imagePath+imageID+imageformat, user['idToken'])
			accesToken = st_response["downloadTokens"]

      data = {"ImageID" : imageID+imageformat,
      "ImageURL" : ImageBaseURL+imageID+imageformat+ImageAuxURL+accesToken,
      "timestamp" : str(timestamp),
      "plateNum" : plateNum
      }

      db.child(UserUID).child(cameraMAC).update(data, user['idToken'])
      os.system("sudo rm "+imagePath+imageID+imageformat)
      f.seek(0)
      f.write("false")
      f.truncate()
      f.close()

except KeyboardInterrupt:
	print("Execution Stopped")
