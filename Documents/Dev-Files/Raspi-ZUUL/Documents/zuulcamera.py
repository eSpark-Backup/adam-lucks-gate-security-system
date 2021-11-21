import os
import time
import json
import pyrebase
from time import sleep
from datetime import datetime


imagePath    = "/home/pi/Pictures/"
ImageBaseURL = "https://firebasestorage.googleapis.com/v0/b/zuul-master.appspot.com/o/images%2F"
ImageAuxURL  = "?alt=media&token="
imageformat  = ".jpg"


config = {
  "apiKey": "AIzaSyBMJa73RYD3-HOwR9ndGWS3SxH9mp4qkJA",
  "authDomain": "zuul-master.firebaseapp.com",
  "databaseURL": "https://zuul-master.firebaseio.com",
  "storageBucket": "zuul-master.appspot.com"
}

firebase = pyrebase.initialize_app(config)
auth = firebase.auth()
user = auth.sign_in_with_email_and_password("ketchuma129@gmail.com", "myzuulsystem!")
db = firebase.database()
st = firebase.storage();


try:
	while True:
		camera = db.child("cameras").child("134:1364:464")
		capture_prog = camera.child("capture_progress").get().val()
		#print(capture_prog)


		if "true" in str(capture_prog).lower():
			print("true")
			imageID = int(time.time())
			timestamp = datetime.utcfromtimestamp(imageID)
			imageID = str(imageID)

			os.system("ffmpeg -rtsp_transport tcp -i rtsp://admin:myZUULsystem!@192.168.1.64:554/Streaming/Channels/101/ -f image2 -vf fps=fps=1 "+imagePath+imageID+imageformat)
			user = auth.refresh(user['refreshToken'])
			st_response = st.child("images/"+imageID+imageformat).put(imagePath+imageID+imageformat, user['idToken'])
			accesToken = st_response["downloadTokens"]

			data = {"ImageID" : imageID+imageformat,
			"ImageURL" : ImageBaseURL+imageID+imageformat+ImageAuxURL+accesToken,
			"timestamp" : str(timestamp),
			"capture_progress" : "False"
			}
			db.child("cameras").child("134:1364:464").update(data, user['idToken'])

except KeyboardInterrupt:
	print("Execution Stopped")