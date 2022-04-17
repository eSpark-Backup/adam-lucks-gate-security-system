import os
import json
import time
import locale
import pyrebase
from time import sleep
from openalpr import Alpr
from datetime import datetime
locale.setlocale(locale.LC_ALL, 'C')

RPI_ID       = "100000004e546d6b"
imagePath    = "/home/ParklandBay/Pictures/"
ImageBaseURL = "https://firebasestorage.googleapis.com/v0/b/zuul-master.appspot.com/o/images%2F"
ImageAuxURL  = "?alt=media&token="
imageformat  = ".jpg"
zoomfactor   = "scale=4*iw:-1, crop=iw/4:ih/4:x=3200:y=2500"
cameraMAC    = "EC:C8:9C:6D:83:F1"
req_node	 = "capture_request"


def OCR(imgpath, imgid, imgformat):
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
        jpeg_bytes = open("/home/ParklandBay/Pictures/capture.jpg", "rb").read()
        results = alpr.recognize_array(jpeg_bytes)
        print(results)

        data = {}
        for plate in results['results']:
            for candidate in plate['candidates']:
                data[candidate['plate']]=candidate['confidence']
                data.update(data)

        plateNum = max(data, key=data.get)
        return plateNum

    finally:
        if alpr:
            alpr.unload()


config = {
  "apiKey": "AIzaSyBMJa73RYD3-HOwR9ndGWS3SxH9mp4qkJA",
  "authDomain": "zuul-master.firebaseapp.com",
  "databaseURL": "https://zuul-master.firebaseio.com",
  "storageBucket": "zuul-master.appspot.com",
  "serviceAccount": "/home/ParklandBay/tmp/zuul-master-firebase-adminsdk-us959-e9bfca113d.json"
}

firebase = pyrebase.initialize_app(config)
auth = firebase.auth()
user = auth.sign_in_with_email_and_password("ketchuma129@gmail.com", "myzuulsystem!")
db = firebase.database()
st = firebase.storage();


try:
	while True:
		capture_prog = db.child(RPI_ID).child(req_node).child("status").get().val()
		#print(capture_prog)


		if "true" in str(capture_prog).lower():
			print(capture_prog)
			cameraMAC = db.child(RPI_ID).child(req_node).child("mac_address").get().val()
			print(cameraMAC)

			imageID = int(time.time())
			timestamp = datetime.utcfromtimestamp(imageID)
			imageID = str(imageID)

			os.system("ffmpeg -rtsp_transport tcp -i rtsp://admin:mon22key@192.168.1.220:554/Streaming/Channels/101/ -f image2 -loglevel quiet -y /home/ParklandBay/Pictures/capture.jpg")
			os.system("ffmpeg -i /home/ParklandBay/Pictures/capture.jpg -vf 'crop=iw/4:ih/4' -loglevel quiet "+imagePath+imageID+imageformat)
			#os.system("ffmpeg -rtsp_transport tcp -i rtsp://admin:myZUULsystem!@192.168.1.64:554/Streaming/Channels/101/ -f image2 -loglevel quiet "+imagePath+imageID+imageformat)
			user = auth.refresh(user['refreshToken'])
			st_response = st.child("images/"+imageID+imageformat).put(imagePath+imageID+imageformat, user['idToken'])
			accesToken = st_response["downloadTokens"]
			#plateNum = OCR()

			data = {"ImageID" : imageID+imageformat,
			"ImageURL" : ImageBaseURL+imageID+imageformat+ImageAuxURL+accesToken,
			"timestamp" : str(timestamp),
			"plateNum" : ""
			}
			db.child(RPI_ID).child(cameraMAC).update(data, user['idToken'])

			data = {"status": "false"}
			db.child(RPI_ID).child(req_node).update(data, user['idToken'])

except KeyboardInterrupt:
	print("Execution Stopped")
