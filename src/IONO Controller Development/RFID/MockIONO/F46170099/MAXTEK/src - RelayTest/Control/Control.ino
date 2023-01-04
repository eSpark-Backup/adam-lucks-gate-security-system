#ifndef DEBUG
#define DEBUG
#endif

#ifndef DEBUG2
#define DEBUG2
#endif


#ifndef UniqueID
#define UniqueID "F46170099"      // The controller Serial Number, same as hostname
#define SecretKey "s5m3g5h9e8"    // The controller SecretKey
#endif


#define ApiUrlAllCodes "http://zuul2.zuulsystems.com/api/get-rfid-codes/"
#define ApiUrlCode "http://zuul2.zuulsystems.com/api/scanned-rfid-code/"


#define SUCCESS 1
#define FAILURE 0


#ifndef READER_TYPE
#define READER_TYPE 3 // 1=default 2=AWID 3=Maxtek
#endif

#include <Bridge.h>
#include <Process.h>
#include <Wiegand.h>
#include <wtDebug.h> // after Bridge.h
#include <Console.h>
#include <HttpClient.h>

//  #define cnst     65536 //RFID Multiplier
//  #define sitecode 1     //Demo community
# define cnst 2359296 // facility code * 65536 (36 * 65536) (For Maxtek only)


  // The object that handles the wiegand protocol
WIEGAND wiegand;
Process controlProc;


const int gaterelay = 7; // On when the gate should open


bool relaysOn = false;

unsigned long currentMillis = 0, newMillis = 0;


String ApiArgs;
String ApiArg;


  // the setup function runs once when you press reset or power the board
void setup() {
  
  wiegand.begin();
  pinMode(gaterelay, OUTPUT);


  //Delay for letting the linux side get a clean boot.
  delay(1000);

  Bridge.begin();
       
  ApiArg = "--user ";
  ApiArg += UniqueID;
  ApiArg += ":";
  ApiArg += SecretKey;
  ApiArg += " -w %{http_code} ";

  ApiArgs = ApiArg;
  ApiArgs += ApiUrlAllCodes;
  ApiArg += ApiUrlCode;





  #ifdef DEBUG
//    Serial.begin(9600);
  #endif


  // Initial run.. just checking
  if (!controlProc.running()) {
    controlProc.begin("/root/control.sh");
    controlProc.run();
  }
}



  // the loop function runs over and over again until power down or reset
void loop() {
  if (wiegand.available()) {
    unsigned long code = wiegand.getCode();
//        PRINT("Wiegand HEX = ");
//        PRINT(code,HEX);
//        PRINT(", DECIMAL = ");
//        PRINT(code);
//        PRINT(", Type W");
//        PRINTLN(wiegand.getWiegandType());

    int code_status = codeReceived(code);
    if (code_status == SUCCESS) {
      digitalWrite(gaterelay, HIGH);
      delay(1000);
      digitalWrite(gaterelay, LOW);
    }
  }
}







int codeReceived(unsigned long code) {
  if (code == 0) return;

  if (!controlProc.running()) {
    
    char str[10] = "";
    code = code - cnst;
    ltoa(code, str, DEC);
      
//    PRINT(" - Running /root/control.sh code ");
//    PRINTLN(str);

    controlProc.begin("/root/control.sh");
    controlProc.addParameter("code");
    controlProc.addParameter(UniqueID);
    controlProc.addParameter(ApiArg);
    controlProc.addParameter(str);
    controlProc.run();

//    PRINT("UniqueID: ");
//    PRINTLN(UniqueID);
//    PRINT("API: ");
//    PRINTLN(ApiArg);
//    PRINT("Code: ");
//    PRINTLN(str);

    if (controlProc.exitValue() == 0) {
//      PRINTLN(" - Code Allowed!");
      return SUCCESS;
    }

    else {
//      PRINTLN(" - Code Denied!");
      return FAILURE;
    }
  }
}
