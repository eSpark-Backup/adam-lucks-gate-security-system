import os
import json
import time
import locale
import pyrebase
from time import sleep
from openalpr import Alpr
from datetime import datetime
locale.setlocale(locale.LC_ALL, 'C')

imagePath    = "/home/pi/Pictures/"
ImageBaseURL = "https://firebasestorage.googleapis.com/v0/b/zuul-master.appspot.com/o/images%2F"
ImageAuxURL  = "?alt=media&token="
imageformat  = ".jpg"
zoomfactor   = "scale=4*iw:-1, crop=iw/4:ih/4:x=3200:y=2500"

plateNum     = 0


def OCR():
    alpr = None
    try:
        alpr = Alpr("us", "/etc/openalpr/openalpr.conf","/usr/share/openalpr/runtime_data",)
        print("Test")

        if not alpr.is_loaded():
            print("Error loading OpenALPR")
        else:
            print("Using OpenALPR " + alpr.get_version())

        alpr.set_top_n(7)
        alpr.set_default_region("wa")
        alpr.set_detect_region(False)
        jpeg_bytes = open("/home/pi/Pictures/capture.jpg", "rb").read()
        results = alpr.recognize_array(jpeg_bytes)
        print(results)
        print(results['results'][0]['plate'])
        return (results['results'][0]['plate'])



    finally:
        if alpr:
            alpr.unload()


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

			os.system("ffmpeg -rtsp_transport tcp -i rtsp://admin:myZUULsystem!@192.168.1.64:554/Streaming/Channels/101/ -f image2 -loglevel quiet -y /home/pi/Pictures/capture.jpg")
			os.system("ffmpeg -i /home/pi/Pictures/capture.jpg -vf 'crop=iw/4:ih/4' -loglevel quiet "+imagePath+imageID+imageformat)
			#os.system("ffmpeg -rtsp_transport tcp -i rtsp://admin:myZUULsystem!@192.168.1.64:554/Streaming/Channels/101/ -f image2 -loglevel quiet "+imagePath+imageID+imageformat)
			user = auth.refresh(user['refreshToken'])
			st_response = st.child("images/"+imageID+imageformat).put(imagePath+imageID+imageformat, user['idToken'])
			accesToken = st_response["downloadTokens"]

			plateNum = OCR()

			data = {"ImageID" : imageID+imageformat,
			"ImageURL" : ImageBaseURL+imageID+imageformat+ImageAuxURL+accesToken,
			"timestamp" : str(timestamp),
			"plateNum" : plateNum,
			"capture_progress" : "False"
			}
			db.child("cameras").child("134:1364:464").update(data, user['idToken'])

except KeyboardInterrupt:
	print("Execution Stopped")