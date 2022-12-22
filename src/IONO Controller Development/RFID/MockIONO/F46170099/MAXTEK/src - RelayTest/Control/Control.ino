//#include <Wiegand.h>
#include <Bridge.h>
#include <wtDebug.h> // after Bridge.h

const int gaterelay = 7; // On when the gate should open

//WIEGAND wg;

void setup() {

	pinMode(gaterelay, OUTPUT);

  Bridge.begin();
  Serial.begin(9600);
//  wg.begin();

}

void loop() {

//  if(wg.available())
//  {
//    Serial.print("Wiegand HEX = ");
//    Serial.print(wg.getCode(),HEX);
//    Serial.print(", DECIMAL = ");
//    Serial.print(wg.getCode());
//    Serial.print(", Type W");
//    Serial.println(wg.getWiegandType());    
//  }
  
  PRINTLN(" Turning Relay ON");
	digitalWrite(gaterelay, HIGH);

	delay(3000);

	PRINTLN(" Turning Relays Off");
	digitalWrite(gaterelay, LOW);

  delay(3000);
}
