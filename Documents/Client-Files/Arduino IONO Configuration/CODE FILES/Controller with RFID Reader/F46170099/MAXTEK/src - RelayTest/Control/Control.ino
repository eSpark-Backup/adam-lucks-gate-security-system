  
#include <Bridge.h>
#include <wtDebug.h> // after Bridge.h

const int relayGate1Pin = A4;     // On when the gate should open
const int relayGate2Pin = A5;     // On when the gate should open
const int relayArmingPin = 5;     // Off when the gate is open
const int relayRedLightPin = 6;   // Off when the gate is open
const int relayGreenLightPin = 7; // On when the gate should open


void setup() {
	pinMode(relayGate1Pin, OUTPUT);
	pinMode(relayGate2Pin, OUTPUT);
	pinMode(relayArmingPin, OUTPUT);
	pinMode(relayRedLightPin, OUTPUT);
	pinMode(relayGreenLightPin, OUTPUT);

  Bridge.begin();
  Serial.begin(9600);
}

void loop() {
  PRINTLN(" Turning Relays ON");
  digitalWrite(relayGate1Pin, HIGH);
	digitalWrite(relayGate2Pin, HIGH);
	digitalWrite(relayRedLightPin, LOW);
	digitalWrite(relayGreenLightPin, HIGH);

	delay(3000);

	PRINTLN(" Turning Relays Off");
	digitalWrite(relayGate1Pin, LOW);
	digitalWrite(relayGate2Pin, LOW);
	digitalWrite(relayRedLightPin, HIGH);
	digitalWrite(relayGreenLightPin, LOW);

  delay(3000);
}
