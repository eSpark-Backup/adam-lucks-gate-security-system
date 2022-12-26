  /*
   Name:    Control.ino
   Created: 11/11/2019 3:00:17 PM
   Author:  Dragos
  */

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





  #ifndef READER_TYPE
  #define READER_TYPE 3 // 1=default 2=AWID 3=Maxtek
  #endif

  #include <Bridge.h>
  #include <Process.h>
  #include <Wiegand.h>
  #include <wtDebug.h> // after Bridge.h


//  #define cnst     65536 //RFID Multiplier
//  #define sitecode 1     //Demo community
# define cnst 2359296 // facility code * 65536 (36 * 65536)
  // The object that handles the wiegand protocol
  WIEGAND wiegand;
  Process controlProc;


  const int gaterelay = 7; // On when the gate should open


  bool relaysOn = false;
  unsigned int relaysLoops = 0;

  bool relayArmingOn = false;
  unsigned long relayArmingMillis = 0;
  //unsigned long relayArmingLoops = 0;
  unsigned long cronMillis = 0;
  unsigned long currentMillis = 0;

  unsigned long codeLast = 0;
  unsigned long codeGood = 0;
  unsigned long codeGood2 = 0;

  unsigned long codeReceivedMillis = 0;
  unsigned int codeFails = 0;
  unsigned long codeFailsMillis = 0;
  int buttonVal;


  String ApiArgs;
  String ApiArg;


  // the setup function runs once when you press reset or power the board
  void setup() {
       
  #if READER_TYPE == 1 // Default
    wiegand.begin();
  #endif
  #if READER_TYPE == 2 // AWID
    wiegand.begin();
  #endif
  #if READER_TYPE == 3 // MAXTEK
    wiegand.begin();
  #endif

    pinMode(gaterelay, OUTPUT);


    //Delay for letting the linux side get a clean boot.
    delay(1000);
    cronMillis = millis()- 3000000;

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
    Serial.begin(9600);
    PRINTLN("Bridge.begin()");
    //PRINTLN(wtFreeRam());
    PRINT("UniqueID: ");
    PRINTLN(UniqueID);
  #endif

    relaysLoops = 10;

    // Initial run.. just checking
    if (!controlProc.running()) {
      controlProc.begin("/root/control.sh");
      controlProc.run();
    }


  }



  // the loop function runs over and over again until power down or reset
  void loop() {

  //  if (millis() - currentMillis > 15000) {
  //    codeReceived(2371966);
  //    currentMillis = millis();
  //  }
    
    if (wiegand.available()) {

  #ifdef DEBUG2
//      if (wiegand.getCode() != 65537 && wiegand.getCode() != 65536) {
        unsigned long code = wiegand.getCode();
        
        PRINT("Wiegand HEX = ");
        PRINT(code,HEX);
        PRINT(", DECIMAL = ");
        PRINT(code);
        PRINT(", Type W");
        PRINTLN(wiegand.getWiegandType());


        /*

        PRINTLN(code, BIN);
        for (int i = 0; i < bits; i++) {
          PRINT(bool(bitRead(code, bits - i - 1)));
        }
        PRINTLN();
        */

        //delay(2000);

//        if (wiegand.hasNoise()) {
//          PRINT("NOISE bin:");
//          PRINT(wiegand.getNoise(), BIN);
//          PRINTLN();
//        }
//    }

  #endif
//      if (wiegand.parityOkW26()) codeReceived(wiegand.getCode());
        codeReceived(code);

  }
    


//    analogWrite(ledPin, brightness/10);
//    brightness = brightness + fadeAmount;
//    // reverse the direction of the fading at the ends of the fade:
//    if (brightness <= 0 || brightness >= 2550) {
//      fadeAmount = -fadeAmount;


//  #ifdef DEBUG2
//      if ((millis() - cronMillis) > 180000) {
//  #else
//      if ((millis() - cronMillis) > 3000000) {
//  #endif
//        
//        cronMillis = millis();
//        
//        // Get All Codes:
       // if (!controlProc.running()) {

       //   PRINTLN(" - Running /root/control.sh allcodes");
       //   PRINT("ApiArg: ");
       //   PRINTLN(ApiArg);
       //   PRINT("ApiArgs: ");
       //   PRINTLN(ApiArgs);

       //   controlProc.begin("/root/control.sh");
       //   controlProc.addParameter("allcodes");
       //   controlProc.addParameter(UniqueID);
       //   controlProc.addParameter(ApiArgs);

       //   controlProc.run();
       
       //   if (controlProc.exitValue() == 0) {
       //     PRINTLN(" - All Codes Fetched!");
       //   } else {
       //     PRINTLN(" - Problem: Unable to fetch all codes!");
       //   }
       // }
//
//
//      }
//    }


    if (relaysLoops > 0) {
      relaysLoops--;


      // Change every 10 loops = 1 second
      //if (relaysLoops % 10 == 0) {
      //  digitalWrite(gaterelay, !digitalRead(gaterelay));
      //  //analogWrite(buzzerPin, 255); // turns it off
      //}


      if (!relaysOn) {
        PRINTLN(" Turning Relays ON");
        relaysOn = true;
        digitalWrite(gaterelay, HIGH);

      }

      delay(100);
      return;

    } else {
      if (relaysOn) {
        PRINTLN(" Turning Relays Off");
        relaysOn = false;

        digitalWrite(gaterelay, LOW);
      }
    }

//    if (relayArmingMillis > 0) {
//      if (relayArmingOn) {
//        // Turn the relay off after 5 sec
//        if ((millis() - relayArmingMillis) > 5000) {
//          PRINTLN(" Turning Arming Relay Off");
//          digitalWrite(relayArmingPin, LOW);
//          relayArmingOn = false;
//          relayArmingMillis = 0;
//        }
//      } else {
//        // Turn the relay on
//        PRINTLN(" Turning Arming Relay ON");
//        digitalWrite(relayArmingPin, HIGH);
//        relayArmingOn = true;
//      }
//    }

  #ifdef DEBUG 
    //relayArmingLoops++;
    //if (relayArmingLoops > 70000) {
    //  relayArmingMillis = millis();
    //  relayArmingLoops = 0;
    //}
  #endif



//    buttonVal = analogRead(buttonOpenPin); // max 1023 = ON ; values lower that 512 mean it is off
//    if (buttonVal >= 512) {
//      if (!buttonOpenOn) {
//        buttonOpenOn = true;
//        PRINTLN("# Button Open ON"); 
//        relaysLoops = 50; // 100 * 0.1 = 10 seconds roughly
//      }
//    } else {
//      if (buttonOpenOn && relaysLoops==0) {
//        buttonOpenOn = false;
//        PRINTLN("# Button Open Off");
//      }
//    }
//
//    buttonVal = analogRead(buttonLearnPin); // max 1023 = ON ; values lower that 512 mean it is off
//    if (buttonVal >= 512) {
//      if (!buttonLearnOn) {
//        buttonLearnOn = true;
//        PRINTLN("# Learning Mode ON");
//        learningMode = true;
//        delay(500);
//      }
//    } else if (buttonLearnOn && !learningMode) buttonLearnOn = false;
//
//
//    buttonVal = analogRead(carSensorPin); // max 1023 = ON ; values lower that 512 mean it is off
//    if (buttonVal >= 512) {
//      if (!carSensorOn) {
//        carSensorOn = true;
//        PRINTLN("# Car Detected");
//        relayArmingMillis = millis();
//        codeLast = 0;
//        delay(200);
//      }
//    } else if (carSensorOn && relayArmingMillis==0 ) carSensorOn = false;
    



  }


  bool isIdentical(const char* a, const char* b) {
    if (strlen(a) != strlen(b)) return false;
    for (int i = 0; a[i] != '\0' && b[i] != '\0'; i++) {
      if (a[i] != b[i])
        return false;
    }
    return true;
  }






  void codeReceived(unsigned long code) {

//    // Silently drop invalid codes
    if (code == 0) return;
    
    if (!controlProc.running()) {
      PRINTLN(" - Running /root/control.sh allcodes");
      PRINT("ApiArg: ");
      PRINTLN(ApiArg);
      PRINT("ApiArgs: ");
      PRINTLN(ApiArgs);

         controlProc.begin("/root/control.sh");
         controlProc.addParameter("allcodes");
         controlProc.addParameter(UniqueID);
         controlProc.addParameter(ApiArgs);

         controlProc.run();
       
         if (controlProc.exitValue() == 0) {
           PRINTLN(" - All Codes Fetched!");
         } else {
           PRINTLN(" - Problem: Unable to fetch all codes!");
         }
       }
//
//  #if READER_TYPE == 2 // AWID
//    if (code <= 65537) return;
//  #endif
//    
//    
//    if (relaysLoops > 0) return; // gate is being opened right now ?
//
//    unsigned long diff = millis() - codeReceivedMillis;
//    
//    // Was a code read in the last 30 sec ?
//    if (codeLast > 0) {
//
//      // The last received code was less than 5 seconds ago ? ignore
//      if (diff < 5000) return;
//
//      // The last received code was more than 15 sec ago ? clear codeLast
//      if (diff > 15000) codeLast = 0; // 15 sec
//
//    }
//
//    // Clear codeGood after 3 minutes since the last code received
//    if (diff > 200000) {
//      PRINTLN(" - clearing codeGood after 3 min");
//      codeGood = 0;
//      codeGood2 = 0;
//    }
//    
//    // already received this code in the last 15 sec ?
//    if (codeLast == code) {
//      PRINTLN(" - Already received this code in the last 15 sec..");
//      return;
//    }
//
//    codeLast = code;
//    codeReceivedMillis = millis();
//
//    // For 5 minutes allow again the last 2 good codes
//    if (codeGood == code || codeGood2 == code) {
//      PRINTLN(" - Code Allowed Again!");
//      relaysLoops = 50; // 100 * 0.1 = 10 seconds roughly
//      return;
//    }
//
//
//    //return true;
//
//
//
    if (!controlProc.running()) {

      char str[10] = "";

      // int tag_num = code - cnst * sitecode;
      // code = cnst * sitecode + tag_num;
      code = code - cnst;
      ltoa(code, str, DEC);
      /*
      ltoa(code, str, HEX);
      uint8_t size = strlen(str);
      for (int i = 0; i < size; i++) {
        str[i] = toupper(str[i]);
      }
      */
      
      PRINT(" - Running /root/control.sh code ");
      PRINTLN(str);

      controlProc.begin("/root/control.sh");
      controlProc.addParameter("code");
      controlProc.addParameter(UniqueID);
      controlProc.addParameter(ApiArg);
      controlProc.addParameter(str);
      controlProc.run();

      PRINT("UniqueID: ");
      PRINTLN(UniqueID);
      PRINT("API: ");
      PRINTLN(ApiArg);
      PRINT("Code: ");
      PRINTLN(str);

      if (controlProc.exitValue() == 0) {
        PRINTLN(" - Code Allowed!");
        if (codeGood != codeGood2) codeGood2=codeGood;
        codeGood=code;
        relaysLoops = 50; // 100 * 0.1 = 10 seconds roughly
        return;
      }
    } 
    else {
      PRINTLN(" - Problem: controlProc already running !?!");
      return;
    }
//
//    // This is an unknown code.. Learn it if in learning mode..
//    if (learningMode) {
//      PRINTLN(" - Learning Mode : TODO: code will be sent to the server for review!");
//      learningMode = false;
//      return;
//    }
//
//    PRINTLN(" - Code Denied!");
//    codeFails++;
//    diff = codeFailsMillis;
//    codeFailsMillis = millis();
//    diff = codeFailsMillis - diff;
//
//    // reset the auth fails counter after after 5 min since the last failed attempt
//    #ifdef DEBUG2
//      if (diff > 120000) codeFails = 1; // 2 minutes
//    #else
//      if (diff > 300000) codeFails = 1; // 5 minutes
//    #endif
//
//    unsigned long sleepMillis = 2000 * codeFails;
//    sleepMillis = min(sleepMillis, 15000); // cap to 15 sec sleep
//
//    // wait 5 sec * number of failed attempts 
//    PRINT(" - Sleeping to prevent abuse: ");
//    PRINT(sleepMillis / 1000);
//    if (codeFails > 1) {
//      PRINT(" sec - reseting in ");
//      PRINT((120000 - diff) / 1000);
//    }
//    PRINTLN(" sec");
//    delay(sleepMillis);
//    return;
  }








  /*



  // Notifies when a reader has been connected or disconnected.
  // Instead of a message, the seconds parameter can be anything you want -- Whatever you specify on `wiegand.onStateChange()`
  void stateChanged(bool plugged, const char* message) {
    PRINT(message);
    PRINTLN(plugged ? "CONNECTED" : "DISCONNECTED");
  }

  // Notifies when a card was read.
  // Instead of a message, the seconds parameter can be anything you want -- Whatever you specify on `wiegand.onReceive()`
  void receivedData(const char* message) {
    
    PRINT(message);
    PRINT(" : dec=");
    //Print value in HEX
    char str[10] = "";
    unsigned long output = 0;
    unsigned long pow2 = 1;
    uint8_t size = wiegand.bits - 1;
    for (int i = 1; i < size; i++) {
      if (!wiegand.dataBinary[i]) continue;
      pow2 = 1;
      for (int j = i+1; j < size; j++) {
        pow2 = pow2 * 2;
      }
      output += pow2 * wiegand.dataBinary[i];
    }
    ltoa(output, str, 16);
    PRINT(output);
    PRINT(" hex=");
    PRINT(output, HEX); 
    PRINT(" str=");

    size = strlen(str);
    for (int i = 0; i < size; i++) {
      str[i] = toupper(str[i]);
    }
    PRINT(str);

    PRINTLN();
    wiegandBinaryData();
    //PRINT("As String: "); 
    //PRINTLN(str);
    codeReceived(str);
  }

  // Notifies when an invalid transmission is detected
  void receivedDataError(Wiegand::DataError error, const char* message) {
    PRINT(message);
    PRINT(Wiegand::DataErrorStr(error));
    PRINT(" ( rt:");
    PRINT(wiegand.read_timeout);
    PRINT(" eb:");
    PRINT(wiegand.expected_bits);
    PRINT(" dm:");
    PRINT(wiegand.decode_messages);
    PRINTLN(")");
    wiegandBinaryData();
  }


  void wiegandBinaryData() {
  #ifdef DEBUG  
    PRINT("RAW: ");
    for (int i = 0; i < wiegand.bits; i++) {
      if (wiegand.dataBinary[i]) {
        PRINT("1");
      } else {
        PRINT("0");
      }
    }
    PRINT("   (bits:");
    PRINT(wiegand.bits);
    PRINT(" parityL:");
    PRINT(wiegand.left_parity);
    PRINT(" parityR:");
    PRINT(wiegand.right_parity);
    PRINT(" parityOk:");
    PRINT(wiegand.parityOk);
    PRINTLN(")");
  #endif
  }


  */

////#include <Wiegand.h>
//#include <Bridge.h>
//#include <wtDebug.h> // after Bridge.h
//
//const int gaterelay = 7; // On when the gate should open
//
////WIEGAND wg;
//
//void setup() {
//
//  pinMode(gaterelay, OUTPUT);
//  delay(1000);
//  
//  Bridge.begin();
//  Serial.begin(9600);
////  wg.begin();
//
//}
//
//void loop() {
//
////  if(wg.available())
////  {
////    Serial.print("Wiegand HEX = ");
////    Serial.print(wg.getCode(),HEX);
////    Serial.print(", DECIMAL = ");
////    Serial.print(wg.getCode());
////    Serial.print(", Type W");
////    Serial.println(wg.getWiegandType());    
////  }
//  
//  PRINTLN(" Turning Relay ON");
//  digitalWrite(gaterelay, HIGH);
//
//  delay(3000);
//
//  PRINTLN(" Turning Relays Off");
//  digitalWrite(gaterelay, LOW);
//
//  delay(3000);
//}
