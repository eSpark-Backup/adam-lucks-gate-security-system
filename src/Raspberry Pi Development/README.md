# AVIGILON PARAMETERS
## Login information
### CAMERA ADMIN 01  
username: administrator  
password AZURA_CCTV_#1! 

username: administrator  
password: AZURA_CCTV_ZUUL#1  

### CAMERA ADMIN 02  
username: admin  
password: myzuulsystem1  

## AVIGILON LPR Playground API Structures
### Login API
1. To access the API, enter Avigilon LPR playground and select Login API.
2. The API requires certain parameters but only four parameters are compulsory. 
3. To obtain the auth token, use the provided user nonce and user key at the end of this README.md and this will generate the Auth Token.
4. The API structure for login API is given below:
```javascript
{
  "username": "administrator",
  "password": "AZURA_CCTV_ZUUL#1",
  "clientName": "azura",
  "authorizationToken": "0014y00002a7wDZAAY:1653661023:8a7a5e982d4697ac631a151124b5bc54a2e4176bf5c6f4b2585ee2a128acbf8b"
}
```
5. Session ID will be returned when this API is called which will be used in further APIs
sessionID: AXgAh_8KEGEC7d9aAEEilZCgHj8RM_8SFgoUJ3IDpJHdTfM95exqcErylFpbdWwaENxhaA69CEcZn4mrLdDzzIQiEMBucZXl10nYoEzAcVYp5lgqBWF6dXJhMiEaEE2erIRywEb_v4iN8kVXy1cqDWFkbWluaXN0cmF0b3I

### Create Webhook on Avigilon Playground
1. API structure and usage is given below:
```javascript
{
    "session": "AXgAh_8KEGEC7d9aAEEilZCgHj8RM_8SFgoUJ3IDpJHdTfM95exqcErylFpbdWwaENxhaA69CEcZn4mrLdDzzIQiEMBucZXl10nYoEzAcVYp5lgqBWF6dXJhMiEaEE2erIRywEb_v4iN8kVXy1cqDWFkbWluaXN0cmF0b3I",
    "webhook": {
        "url": "https://newman-api.getpostman.com/run/20430047/97cdb496-2512-4817-ba8e-437070ff856f",
        "heartbeat": {
            "enable": true,
            "frequencyMs": 10000
        },
        "authenticationToken": "0014y00002a7wDZAAY:1652991440:c1e2b1fcc4cbe99f2ae489b39f1db7abbb6cebd1947f19e54cb1c91a4f6eec42",
        "eventTopics": {
            "whitelist": [
                "DEVICE_LPR_PLATE_UPDATE"
            ]
        }
    }
}
```

### Read Webhook on Avigilon
1. A Web URL can be callled in the browser that is able to access Avigilon Playground. The URL is obtained via **Read Webhook API** in playground API list. The session ID will be used that was obtained at the time of calling Login API.

> https://192.168.2.242/mt/api/rest/v1/webhooks?session=AXgAh_8KEGEC7d9aAEEilZCgHj8RM_8SFgoUpdN8_FB8LCEFQ6KTkF7prPcjNB4aEIxJhZvwU0z1pSJYFb4meKYiEMBucZXl10nYoEzAcVYp5lgqBWF6dXJhMiEaEE2erIRywEb_v4iN8kVXy1cqDWFkbWluaXN0cmF0b3I

### Update Webhook on Avigilon
1. The Read Webhook API will also return device ID for all the registered webhooks that can be used to update them as well with the API structure provided below:
```javascript
{
  "session": "AXgAh_8KEGEC7d9aAEEilZCgHj8RM_8SFgoUpdN8_FB8LCEFQ6KTkF7prPcjNB4aEIxJhZvwU0z1pSJYFb4meKYiEMBucZXl10nYoEzAcVYp5lgqBWF6dXJhMiEaEE2erIRywEb_v4iN8kVXy1cqDWFkbWluaXN0cmF0b3I",
  "webhook": {
    "id": "jM-c4uLAQJqdA6F2EKUTfA",
    "url": "http://192.168.2.151:9001/hooks/response_fb",
    "heartbeat": {
      "enable": true,
      "frequencyMs":30000
    },
    "authenticationToken": "0014y00002a7wDZAAY:1653661023:8a7a5e982d4697ac631a151124b5bc54a2e4176bf5c6f4b2585ee2a128acbf8b",
    "eventTopics": {
      "whitelist": [
        "DEVICE_LPR_PLATE_UPDATE"
      ]
    }
  }
}
```

### Delete Webhook on Avigilon
1. To delete a registered webhook, again device ID will be used. The API structure for that is given below:
```javascript
{
  "session": "AXgAh_8KEGEC7d9aAEEilZCgHj8RM_8SFgoUJ3IDpJHdTfM95exqcErylFpbdWwaENxhaA69CEcZn4mrLdDzzIQiEMBucZXl10nYoEzAcVYp5lgqBWF6dXJhMiEaEE2erIRywEb_v4iN8kVXy1cqDWFkbWluaXN0cmF0b3I",
  "ids": [
    "IEziwh1iRfSZtiR7DNoCuQ",
    "c3VAdb6uR066K1Zk5uS0jw",
    "4PwO4KAmQxCQXzow0qMZGg"
  ]
}
```
# AVIGILON CAMERA IMPORTANT COMMANDS
## URL for Still Image Capture
1. http://107.128.123.204/media/cam0/still.jpg?res=max (The IP Address may vary case to case)

## URL for Live RTSP Stream
1. rtsp://admin:myzuulsystem1@107.128.123.204/defaultPrimary?mtu=1440&streamType=u (The IP and username and password can vary case to case)


# DOORBIRD PARAMETERS
## User Credentials and necessary Info
username: ghnjcs0001  
password: H4aEZcxrrU  
rtsp: rtsp://ghnjcs0001:H4aEZcxrrU@192.168.1.246/mpeg/1080p/media.amp


### AVIGILON AUTHTOKEN PARAMETERS
userNonce: 0014y00002a7wDZAAY  
userKey: c1a418c5b5e00ca7815de44cd672b75ed503386850b3648df8571185d6f9b34e  
