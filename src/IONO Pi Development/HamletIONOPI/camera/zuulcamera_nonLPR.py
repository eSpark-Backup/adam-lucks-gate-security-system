import os
import json
import time
import locale
import pyrebase
from time import sleep
from datetime import datetime

UserUID      = "4AA9BoP4x5R9woI3ofDit8gxe473"
RPI_ID       = "10000000e670fa79@email.com"
RPI_PASS     = "udC92yIq4eau1Ya"
imagePath    = "/home/pi/Pictures/"
ImageBaseURL = "https://firebasestorage.googleapis.com/v0/b/zuul-master.appspot.com/o/images%2F"
ImageAuxURL  = "?alt=media&token="
imageformat  = ".jpg"
zoomfactor   = "scale=4*iw:-1, crop=iw/4:ih/4:x=3200:y=2500"
cameraMAC    = "28:36:13:55:00:DC"

config = {
  "apiKey": "AIzaSyBMJa73RYD3-HOwR9ndGWS3SxH9mp4qkJA",
  "authDomain": "zuul-master.firebaseapp.com",
  "databaseURL": "https://zuul-master.firebaseio.com/",
  "storageBucket": "zuul-master.appspot.com"
}

firebase = pyrebase.initialize_app(config)
auth = firebase.auth()
user = auth.sign_in_with_email_and_password(RPI_ID, RPI_PASS)
db = firebase.database()
st = firebase.storage();

    
imageID = int(time.time())
timestamp = datetime.utcfromtimestamp(imageID)
imageID = str(imageID)
print(timestamp)

os.system("ffmpeg -rtsp_transport tcp -i rtsp://admin:Club1ETsecurity!@192.168.1.101/ -f image2 -loglevel quiet -y /home/pi/Pictures/capture.jpg")
os.system("ffmpeg -i /home/pi/Pictures/capture.jpg -vf 'crop=iw/2:ih/2' -loglevel quiet "+imagePath+imageID+imageformat)

user = auth.refresh(user['refreshToken'])
st_response = st.child("images/"+imageID+imageformat).put(imagePath+imageID+imageformat, user['idToken'])
accesToken = st_response["downloadTokens"]

data = {
  "ImageID" : imageID+imageformat,
  "ImageURL" : ImageBaseURL+imageID+imageformat+ImageAuxURL+accesToken,
  "timestamp" : str(timestamp),
  "plateNum" : ""
}

db.child(UserUID).child(cameraMAC).update(data, user['idToken'])
os.system("sudo rm "+imagePath+imageID+imageformat)
f = open('log_file.txt', 'a')
f.write(str(timestamp)+" Image Upload Success "+imageID+imageformat+"\n")
f.close()


#except KeyboardInterrupt:
#  print("Execution Stopped")
