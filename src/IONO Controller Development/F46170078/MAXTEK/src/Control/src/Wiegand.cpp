#include "Wiegand.h"

#if defined(ESP8266)
    #define INTERRUPT_ATTR ICACHE_RAM_ATTR
#elif defined(ESP32)
	#define INTERRUPT_ATTR IRAM_ATTR
#else
    #define INTERRUPT_ATTR
#endif

volatile unsigned long WIEGAND::_cardTempHigh=0;
volatile unsigned long WIEGAND::_cardTemp=0;
volatile unsigned long WIEGAND::_lastWiegand=0;
unsigned long WIEGAND::_code=0;
volatile int WIEGAND::_bitCount=0;	
int WIEGAND::_wiegandType=0;

unsigned int WIEGAND::read_timeout = 25;
uint8_t WIEGAND::expected_bits = 0;
unsigned long	WIEGAND::_noise = 0;
bool	WIEGAND::_hasNoise = false;
bool	WIEGAND::_parityOk = false;






WIEGAND::WIEGAND()
{
}

unsigned long WIEGAND::getCode() {
	return _code;
}
unsigned long WIEGAND::getNoise() {
	return _noise;
}

int WIEGAND::getWiegandType()
{
	return _wiegandType;
}

bool WIEGAND::available()
{
	bool ret;
	noInterrupts();
	ret=DoWiegandConversion();
	interrupts();
	return ret;
}

bool WIEGAND::hasNoise() {
	if (_hasNoise) {
		_hasNoise = false;
		return true;
	}
	return false;
}

bool WIEGAND::parityOkW26() {
	if (_code==0) return false;
	if (_wiegandType != 26) return false;
	return _parityOk;

}


void WIEGAND::begin() {
	begin(2, 3, 25, 0);
}

void WIEGAND::begin(unsigned int readTimeout, uint8_t expectedBits) {
	begin(2,3, readTimeout, expectedBits);
}

void WIEGAND::begin(int pinD0, int pinD1, unsigned int readTimeout, uint8_t expectedBits)
{
	_lastWiegand = 0;
	_cardTempHigh = 0;
	_cardTemp = 0;
	_code = 0;
	_wiegandType = 0;
	_bitCount = 0;  
	read_timeout = readTimeout;
	expected_bits = expectedBits;

	pinMode(pinD0, INPUT_PULLUP);					// Set D0 pin as input
	pinMode(pinD1, INPUT_PULLUP);					// Set D1 pin as input
	
	attachInterrupt(digitalPinToInterrupt(pinD0), ReadD0, FALLING);  // Hardware interrupt - high to low pulse
	attachInterrupt(digitalPinToInterrupt(pinD1), ReadD1, FALLING);  // Hardware interrupt - high to low pulse
}

INTERRUPT_ATTR void WIEGAND::ReadD0 ()
{
	_bitCount++;				// Increament bit count for Interrupt connected to D0
	if (_bitCount>31)			// If bit count more than 31, process high bits
	{
		_cardTempHigh |= ((0x80000000 & _cardTemp)>>31);	//	shift value to high bits
		_cardTempHigh <<= 1;
		_cardTemp <<=1;
	}
	else
	{
		_cardTemp <<= 1;		// D0 represent binary 0, so just left shift card data
	}
	_lastWiegand = millis();	// Keep track of last wiegand bit received
}

INTERRUPT_ATTR void WIEGAND::ReadD1()
{
	_bitCount ++;				// Increment bit count for Interrupt connected to D1
	if (_bitCount>31)			// If bit count more than 31, process high bits
	{
		_cardTempHigh |= ((0x80000000 & _cardTemp)>>31);	// shift value to high bits
		_cardTempHigh <<= 1;
		_cardTemp |= 1;
		_cardTemp <<=1;
	}
	else
	{
		_cardTemp |= 1;			// D1 represent binary 1, so OR card data with 1 then
		_cardTemp <<= 1;		// left shift card data
	}
	_lastWiegand = millis();	// Keep track of last wiegand bit received
}

unsigned long WIEGAND::GetCardId (volatile unsigned long *codehigh, volatile unsigned long *codelow, char bitlength)
{

	if (bitlength == 26) {							// EM tag
			   
		boolean left_parity = false;  // even parity 
		boolean right_parity = false; // odd parity 

		for (int i = 0; i < _wiegandType / 2; i++) {
			left_parity = (left_parity != bool(bitRead(*codelow, _wiegandType - i - 1))); // which bit to read, starting at 0 for the least-significant (rightmost) bit
		}
		for (int i = _wiegandType / 2; i < _wiegandType; i++) {
			right_parity = (right_parity != bool(bitRead(*codelow, _wiegandType - i - 1))); // which bit to read, starting at 0 for the least-significant (rightmost) bit
		}

		_parityOk = bool(!left_parity && right_parity);

		return (*codelow & 0x1FFFFFE) >> 1;
	}

	if (bitlength==34)								// Mifare 
	{
		*codehigh = *codehigh & 0x03;				// only need the 2 LSB of the codehigh
		*codehigh <<= 30;							// shift 2 LSB to MSB		
		*codelow >>=1;
		return *codehigh | *codelow;
	}
	return *codelow;								// EM tag or Mifare without parity bits
}

char translateEnterEscapeKeyPress(char originalKeyPress) {
	switch(originalKeyPress) {
	case 0x0b:        // 11 or * key
		return 0x0d;  // 13 or ASCII ENTER

	case 0x0a:        // 10 or # key
		return 0x1b;  // 27 or ASCII ESCAPE

	default:
		return originalKeyPress;
	}
}

bool WIEGAND::DoWiegandConversion ()
{
	unsigned long cardID;
	unsigned long sysTick = millis();
	
	// if no more signal coming through after 25ms
	if ( ((sysTick - _lastWiegand) > read_timeout) || ((expected_bits > 0) && (_bitCount>= expected_bits)) ) {
		if ((_bitCount==24) || (_bitCount==26) || (_bitCount==32) || (_bitCount==34) || (_bitCount==8) || (_bitCount==4)) 	// bitCount for keypress=4 or 8, Wiegand 26=24 or 26, Wiegand 34=32 or 34
		{
			_hasNoise = false;
			_parityOk = false;
			_cardTemp >>= 1;			// shift right 1 bit to get back the real value - interrupt done 1 left shift in advance
			if (_bitCount>32)			// bit count more than 32 bits, shift high bits right to make adjustment
			_cardTempHigh >>= 1;	

			if (_bitCount==8)		// keypress wiegand with integrity
			{
				// 8-bit Wiegand keyboard data, high nibble is the "NOT" of low nibble
				// eg if key 1 pressed, data=E1 in binary 11100001 , high nibble=1110 , low nibble = 0001 
				char highNibble = (_cardTemp & 0xf0) >>4;
				char lowNibble = (_cardTemp & 0x0f);
				_wiegandType=_bitCount;					
				_bitCount=0;
				_cardTemp=0;
				_cardTempHigh=0;
				
				if (lowNibble == (~highNibble & 0x0f))		// check if low nibble matches the "NOT" of high nibble.
				{
					_code = (int)translateEnterEscapeKeyPress(lowNibble);
					return true;
				}
				else {
					_lastWiegand=sysTick;
					_bitCount=0;
					_cardTemp=0;
					_cardTempHigh=0;
					return false;
				}

				// TODO: Handle validation failure case!
			}
			else if (4 == _bitCount) {
				// 4-bit Wiegand codes have no data integrity check so we just
				// read the LOW nibble.
				_code = (int)translateEnterEscapeKeyPress(_cardTemp & 0x0000000F);

				_wiegandType = _bitCount;
				_bitCount = 0;
				_cardTemp = 0;
				_cardTempHigh = 0;

				return true;
			}
			else		// wiegand 26 or wiegand 34
			{
				cardID = GetCardId (&_cardTempHigh, &_cardTemp, _bitCount);
				_wiegandType=_bitCount;
				_bitCount=0;
				_cardTemp=0;
				_cardTempHigh=0;
				_code=cardID;
				return true;
			}
		}
		else
		{
			// well time over 25 ms and bitCount !=8 , !=26, !=34 , must be noise or nothing then.
			_lastWiegand=sysTick;
			_noise = _cardTemp;
			if (_noise > 0) _hasNoise = true;
			_bitCount=0;			
			_cardTemp=0;
			_cardTempHigh=0;
			return false;
		}	
	}
	else
	return false;
}
