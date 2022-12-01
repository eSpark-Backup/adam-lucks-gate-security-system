import os
import json
import time
import locale
import pyrebase
from time import sleep
from datetime import datetime

UserID       = "UtP3EuuKYQMy6yDNdrps1hVGtFa2"
RPI_ID       = "100000004e546d6b"
imagePath    = "/home/ParklandBay/Pictures/"
ImageBaseURL = "https://firebasestorage.googleapis.com/v0/b/zuul-master.appspot.com/o/images%2F"
ImageAuxURL  = "?alt=media&token="
imageformat  = ".jpg"
zoomfactor   = "scale=4*iw:-1, crop=iw/4:ih/4:x=3200:y=2500"
cameraMAC    = "EC:C8:9C:6D:83:F1"
req_node	   = "capture_request"

config = {
  "apiKey": "AIzaSyBMJa73RYD3-HOwR9ndGWS3SxH9mp4qkJA",
  "authDomain": "zuul-master.firebaseapp.com",
  "databaseURL": "https://zuul-master.firebaseio.com/",
  "storageBucket": "zuul-master.appspot.com"
}

firebase = pyrebase.initialize_app(config)
auth = firebase.auth()
user = auth.sign_in_with_email_and_password("100000004e546d6b@email.com", ":=5*4p;PNV7d&pu$")
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

			os.system("ffmpeg -rtsp_transport tcp -i rtsp://admin:mon22key@192.168.1.220:554/Streaming/Channels/101/ -f image2 -loglevel quiet -y /home/ParklandBay/Pictures/capture.jpg")
			os.system("ffmpeg -i /home/ParklandBay/Pictures/capture.jpg -vf 'crop=iw/2:ih/2' -loglevel quiet "+imagePath+imageID+imageformat)

			user = auth.refresh(user['refreshToken'])
			st_response = st.child("images/"+imageID+imageformat).put(imagePath+imageID+imageformat, user['idToken'])
			accesToken = st_response["downloadTokens"]

			data = {"ImageID" : imageID+imageformat,
			"ImageURL" : ImageBaseURL+imageID+imageformat+ImageAuxURL+accesToken,
			"timestamp" : str(timestamp),
			"plateNum" : ""
			}
			db.child(UserID).child(cameraMAC).update(data, user['idToken'])
			os.system("sudo rm "+imagePath+imageID+imageformat)
			f.seek(0)
			f.write("false")
			f.truncate()
			f.close()
		

except KeyboardInterrupt:
	print("Execution Stopped")
