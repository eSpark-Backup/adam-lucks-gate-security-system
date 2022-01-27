/*
 Name:		wtDebug.h
 Created:	11/11/2019 8:10:52 AM
 Author:	Dragos
*/

#ifndef _wtDebug_h
#define _wtDebug_h

#if defined(ARDUINO) && ARDUINO >= 100
	#include "arduino.h"
#endif



#ifdef DEBUG    //Macros are usually in all capital letters.  // Console.flush();   Serial.flush();
	#ifdef CONSOLE_H_
		#define PRINT(...)    Console.print(__VA_ARGS__); Serial.print(__VA_ARGS__)
		#define PRINTLN(...)  Console.println(__VA_ARGS__); Serial.println(__VA_ARGS__)
	#else
		#define PRINT(...)    Serial.print(__VA_ARGS__)
		#define PRINTLN(...)  Serial.println(__VA_ARGS__)
	#endif  
	#define DBGDELAY(...)    delay(__VA_ARGS__)

#else
	#define PRINT(...)     //now defines a blank line
	#define PRINTLN(...)     //now defines a blank line
	#define DBGDELAY(...)     //now defines a blank line
#endif



int wtFreeRam();
void wtPinsStatus();

#endif