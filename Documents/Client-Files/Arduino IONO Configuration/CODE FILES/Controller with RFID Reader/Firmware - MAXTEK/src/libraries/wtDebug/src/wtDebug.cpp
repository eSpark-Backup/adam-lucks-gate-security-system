/*
 Name:		wtDebug.cpp
 Created:	11/11/2019 8:10:52 AM
 Author:	Dragos
*/

#include "wtDebug.h"



int wtFreeRam() {
	extern int __heap_start, *__brkval;
	int v;
	return (int)&v - (__brkval == 0 ? (int)&__heap_start : (int)__brkval);
}


/*
#include <avr/interrupt.h>
#include <avr/sleep.h>

void stop() { return;
	set_sleep_mode(SLEEP_MODE_PWR_DOWN);
	cli();  // Disable interrupts
	sleep_mode();
}

*/