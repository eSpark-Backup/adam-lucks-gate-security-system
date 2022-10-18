#ifndef _WIEGAND_H
#define _WIEGAND_H

#if defined(ARDUINO) && ARDUINO >= 100
#include "Arduino.h"
#else
#include "WProgram.h"
#endif

class WIEGAND {

public:
	WIEGAND();
	void begin();
	void begin(unsigned int readTimeout, uint8_t expectedBits);
	void begin(int pinD0, int pinD1, unsigned int readTimeout, uint8_t expectedBits);
	//void begin(int pinD0, int pinIntD0, int pinD1, int pinIntD1);
	bool available();
	bool parityOkW26();
	bool hasNoise();
	unsigned long getCode();
	unsigned long getNoise();
	int getWiegandType();


	
private:
	static void ReadD0();
	static void ReadD1();
	static bool DoWiegandConversion ();
	static unsigned long GetCardId (volatile unsigned long *codehigh, volatile unsigned long *codelow, char bitlength);
	
	static volatile unsigned long 	_cardTempHigh;
	static volatile unsigned long 	_cardTemp;
	static volatile unsigned long 	_lastWiegand;
	static volatile int				_bitCount;	
	static int				_wiegandType;
	static unsigned long	_code;
	static unsigned long	_noise;
	static bool	_hasNoise;
	static bool	_parityOk;

	static unsigned int read_timeout; 
	static uint8_t expected_bits;
};

#endif
