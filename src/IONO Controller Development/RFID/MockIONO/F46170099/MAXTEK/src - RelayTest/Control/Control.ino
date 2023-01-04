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


//  #define cnst     65536 //RFID Multiplier
//  #define sitecode 1     //Demo community
# define cnst 2359296 // facility code * 65536 (36 * 65536) (For Maxtek only)
#define MAX_BITS 100 

  // The object that handles the wiegand protocol
//WIEGAND wiegand;
//Process controlProc;

unsigned char databits[MAX_BITS];
unsigned char bitCount;
unsigned long facilityCode=0;
unsigned long cardCode=0;
unsigned long cardnum=0;

const int gaterelay = 7; // On when the gate should open
const int dat0 = 2; // DATA0 (INT0)
const int dat1 = 3; // DATA1 (INT1)


unsigned long currentMillis = 0, newMillis = 0;


String ApiArgs;
String ApiArg;

void ISR_INT0()
{
  bitCount++; 
  
}

// interrupt that happens when INT1 goes low (1 bit)
void ISR_INT1()
{
  databits[bitCount] = 1;
  bitCount++;
}


  // the setup function runs once when you press reset or power the board
void setup() {
  
//  wiegand.begin();
  pinMode(gaterelay, OUTPUT);
  pinMode(dat0, INPUT);
  pinMode(dat1, INPUT);

  attachInterrupt(0, ISR_INT0, FALLING);  
  attachInterrupt(1, ISR_INT1, FALLING);
  
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
//  if (!controlProc.running()) {
//    controlProc.begin("/root/control.sh");
//    controlProc.run();
//  }
}



  // the loop function runs over and over again until power down or reset
void loop() {
//  if (wiegand.available()) {
//    unsigned long code = wiegand.getCode();
////        PRINT("Wiegand HEX = ");
////        PRINT(code,HEX);
////        PRINT(", DECIMAL = ");
////        PRINT(code);
////        PRINT(", Type W");
////        PRINTLN(wiegand.getWiegandType());
//
//    int code_status = codeReceived(code);
//    if (code_status == SUCCESS) {
//      digitalWrite(gaterelay, HIGH);
//      delay(1000);
//      digitalWrite(gaterelay, LOW);
//    }
//  }
  
  rfid();


}



void rfid() {


  if (bitCount > 25) {
    unsigned char i;  

    if (bitCount == 35)
    {
      // 35 bit HID Corporate 1000 format
      // facility code = bits 2 to 14
      for (i=2; i<14; i++)
      {
         facilityCode <<=1;
         facilityCode |= databits[i];
      }
      
      // card code = bits 15 to 34
      for (i=14; i<34; i++)
      {
         cardCode <<=1;
         cardCode |= databits[i];
      }
      
      printBits();
    }
    else if (bitCount == 26)
    {
      
      // standard 26 bit format
      // facility code = bits 2 to 9
      for (i=1; i<9; i++)
      {
         facilityCode <<=1;
         facilityCode |= databits[i];
      }
      
      // card code = bits 10 to 23
      for (i=9; i<25; i++)
      {
         cardCode <<=1;
         cardCode |= databits[i];
      }
      char binchar[24];
      String bitstring;
      for(i=1; i<25;i++){bitstring = bitstring + databits[i];}

      bitstring.toCharArray(binchar, 25);
      
      long  b, k, m, n;
        long  len, sum = 0;

        len = strlen(binchar) - 1;
        for(k = 0; k <= len; k++)
        {
                n = (binchar[k] - '0'); // char to numeric value
                //Serial.print(n);
               if ((n > 1) || (n < 0))
                {
                        puts("\n\n ERROR! BINARY has only 1 and 0!\n");
                      
                }
                for(b = 1, m = len; m > k; m--)
                {
                        // 1 2 4 8 16 32 64 ... place-values, reversed here
                        b *= 2;
                        
                }
                
                // sum it up
                //Serial.println(sum);
                sum = sum + n * b;
                //Serial.println(sum);  // uncomment to show the way this works
        }
        
  
      cardnum=sum;      
      printBits();  
    }
    else {
     PRINTLN("Unable to decode."); 
    }

     // cleanup and get ready for the next card
     bitCount = 0;
     facilityCode = 0;
     cardCode = 0;
     for (i=0; i<MAX_BITS; i++) 
     {
       databits[i] = 0;
     }
  }
}


void printBits()
{
      // I really hope you can figure out what this function does
      PRINT("FC = ");
      PRINT(facilityCode);
      PRINT(", CC = ");
      PRINT(cardCode);
      PRINT(", CN = ");
      PRINTLN(cardnum);
}

int codeReceived(unsigned long code) {
//  if (code == 0) return;
//
//  if (!controlProc.running()) {
//    
//    char str[10] = "";
//    code = code - cnst;
//    ltoa(code, str, DEC);
//      
////    PRINT(" - Running /root/control.sh code ");
////    PRINTLN(str);
//
//    controlProc.begin("/root/control.sh");
//    controlProc.addParameter("code");
//    controlProc.addParameter(UniqueID);
//    controlProc.addParameter(ApiArg);
//    controlProc.addParameter(str);
//    controlProc.run();
//
////    PRINT("UniqueID: ");
////    PRINTLN(UniqueID);
////    PRINT("API: ");
////    PRINTLN(ApiArg);
////    PRINT("Code: ");
////    PRINTLN(str);
//
//    if (controlProc.exitValue() == 0) {
////      PRINTLN(" - Code Allowed!");
//      return SUCCESS;
//    }
//
//    else {
////      PRINTLN(" - Code Denied!");
//      return FAILURE;
//    }
//  }
}
