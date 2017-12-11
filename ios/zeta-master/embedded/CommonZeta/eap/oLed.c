#include <msp430.h>
#include <stdbool.h>
#include "oLed.h"

/*MACROS*/
#define COMMANDCONTROL 0x80
#define DATACONTROL 0xC0
#define DEVADDRESS 0x3C
#define RESETMASK (1 << 2)
#define SDAMASK (1 << 4)
#define SCLMASK (1 << 7)

#define RESET_SET()			(P2OUT |= RESETMASK)
#define RESET_CLEAR() 		(P2OUT &= ~RESETMASK)
#define RESET_MAKEOUTPUT() 	(P2DIR |= RESETMASK)

#define SCL_SET()			(P1OUT |= SCLMASK)
#define SCL_CLEAR() 		(P1OUT &= ~SCLMASK)
#define SCL_GET() 			(P1IN & SCLMASK ? 1 : 0)
#define SCL_MAKEOUTPUT() 	(P1DIR |= SCLMASK)
#define SCL_MAKEINPUT() 	(P1DIR &= ~SCLMASK)
#define SCL_SETPULLUP() 	(P1REN |= SCLMASK)

#define SDA_SET()			(P1OUT |= SDAMASK)
#define SDA_CLEAR() 		(P1OUT &= ~SDAMASK)
#define SDA_GET() 			(P1IN & SDAMASK ? 1 : 0)
#define SDA_MAKEOUTPUT() 	(P1DIR |= SDAMASK)
#define SDA_MAKEINPUT() 	(P1DIR &= ~SDAMASK)
#define SDA_SETPULLUP() 	(P1REN |= SDAMASK)

/*TYPE DEFINITIONS*/
typedef enum {DATA, COMMAND} DCselect;
typedef struct {
	uint8_t line;
	uint8_t column;
} Cursor;

/*PRIVATE FUNCTION PROTOTYPES*/

/*I2C function prototypes*/
static void i2cDelay(void);
static uint8_t i2cMasterWrite(uint8_t sByte);
static void i2cStart(void);
static void i2cStop(void);
static void i2cWrite(uint8_t devAddr, uint8_t regAddr, uint8_t regData);

/*oLed function prototypes*/
static void entireOn( bool ignore );
static void masterConfiguration( uint8_t select );
static void sendNop( void );
static void sendByte( DCselect DC, uint8_t sByte );
static void setAreaColorMode( bool color, bool lowPower );
static void setBankColor( uint8_t bankHalf, uint8_t color1, uint8_t color2, uint8_t color3, uint8_t color4, uint8_t color5, uint8_t color6, uint8_t color7, uint8_t color8, uint8_t color9, uint8_t color10, uint8_t color11, uint8_t color12, uint8_t color13, uint8_t color14, uint8_t color15, uint8_t color16);
static void setBrightness( uint8_t brightness );
static void setClock( uint8_t frequency, uint8_t divideRatio );
static void setColumnAddress( uint8_t startAddr, uint8_t endAddr);
static void setComPinConfig( uint8_t cpConfig );
static void setComRemap( bool remap );
static void setContrastControl( uint8_t contrast );
static void setDisplayOffset( uint8_t shift );
static void setLookUpTable( uint8_t pulse0, uint8_t pulseA, uint8_t pulseB, uint8_t pulseC );
static void setMemAddressMode( uint8_t mode );
static void setMultiplexRatio( uint8_t ratio );
static void setNormal( bool normal );
static void setPageAddress( uint8_t startAddr, uint8_t endAddr);
static void setPageStartAddress( uint8_t start );
static void setPrecharge( uint8_t phase1, uint8_t phase2 );
static void setSegmentRemap( uint8_t select );
static void setStartColumn( uint8_t start );
static void setStartLine( uint8_t line );
static void setVCOMH( uint8_t level );

/*PRIVATE CONSTANTS*/
static const uint8_t font[][5] = {
        { 0x00, 0x00, 0x00, 0x00, 0x00 }, // " "
        { 0x00, 0x00, 0x4f, 0x00, 0x00 }, // !
        { 0x00, 0x07, 0x00, 0x07, 0x00 }, // "
        { 0x14, 0x7f, 0x14, 0x7f, 0x14 }, // "#"
        { 0x24, 0x2a, 0x7f, 0x2a, 0x12 }, // $
        { 0x23, 0x13, 0x08, 0x64, 0x62 }, // %
        { 0x36, 0x49, 0x55, 0x22, 0x50 }, // &
        { 0x00, 0x05, 0x03, 0x00, 0x00 }, // '
        { 0x00, 0x1c, 0x22, 0x41, 0x00 }, // (
        { 0x00, 0x41, 0x22, 0x1c, 0x00 }, // )
        { 0x14, 0x08, 0x3e, 0x08, 0x14 }, // *
        { 0x08, 0x08, 0x3e, 0x08, 0x08 }, // +
        { 0x00, 0x50, 0x30, 0x00, 0x00 }, // ,
        { 0x08, 0x08, 0x08, 0x08, 0x08 }, // -
        { 0x00, 0x60, 0x60, 0x00, 0x00 }, // .
        { 0x20, 0x10, 0x08, 0x04, 0x02 }, // /
        { 0x3e, 0x51, 0x49, 0x45, 0x3e }, // 0
        { 0x00, 0x42, 0x7f, 0x40, 0x00 }, // 1
        { 0x42, 0x61, 0x51, 0x49, 0x46 }, // 2
        { 0x21, 0x41, 0x45, 0x4b, 0x31 }, // 3
        { 0x18, 0x14, 0x12, 0x7f, 0x10 }, // 4
        { 0x27, 0x45, 0x45, 0x45, 0x39 }, // 5
        { 0x3c, 0x4a, 0x49, 0x49, 0x30 }, // 6
        { 0x01, 0x71, 0x09, 0x05, 0x03 }, // 7
        { 0x36, 0x49, 0x49, 0x49, 0x36 }, // 8
        { 0x06, 0x49, 0x49, 0x29, 0x1e }, // 9
        { 0x00, 0x36, 0x36, 0x00, 0x00 }, // :
        { 0x00, 0x56, 0x36, 0x00, 0x00 }, // ;
        { 0x08, 0x14, 0x22, 0x41, 0x00 }, // <
        { 0x14, 0x14, 0x14, 0x14, 0x14 }, // =
        { 0x00, 0x41, 0x22, 0x14, 0x08 }, // >
        { 0x02, 0x01, 0x51, 0x09, 0x06 }, // ?
        { 0x32, 0x49, 0x79, 0x41, 0x3e }, // @
        { 0x7e, 0x11, 0x11, 0x11, 0x7e }, // A
        { 0x7f, 0x49, 0x49, 0x49, 0x36 }, // B
        { 0x3e, 0x41, 0x41, 0x41, 0x22 }, // C
        { 0x7f, 0x41, 0x41, 0x22, 0x1c }, // D
        { 0x7f, 0x49, 0x49, 0x49, 0x41 }, // E
        { 0x7f, 0x09, 0x09, 0x09, 0x01 }, // F
        { 0x3e, 0x41, 0x49, 0x49, 0x7a }, // G
        { 0x7f, 0x08, 0x08, 0x08, 0x7f }, // H
        { 0x00, 0x41, 0x7f, 0x41, 0x00 }, // I
        { 0x20, 0x40, 0x41, 0x3f, 0x01 }, // J
        { 0x7f, 0x08, 0x14, 0x22, 0x41 }, // K
        { 0x7f, 0x40, 0x40, 0x40, 0x40 }, // L
        { 0x7f, 0x02, 0x0c, 0x02, 0x7f }, // M
        { 0x7f, 0x04, 0x08, 0x10, 0x7f }, // N
        { 0x3e, 0x41, 0x41, 0x41, 0x3e }, // O
        { 0x7f, 0x09, 0x09, 0x09, 0x06 }, // P
        { 0x3e, 0x41, 0x51, 0x21, 0x5e }, // Q
        { 0x7f, 0x09, 0x19, 0x29, 0x46 }, // R
        { 0x46, 0x49, 0x49, 0x49, 0x31 }, // S
        { 0x01, 0x01, 0x7f, 0x01, 0x01 }, // T
        { 0x3f, 0x40, 0x40, 0x40, 0x3f }, // U
        { 0x1f, 0x20, 0x40, 0x20, 0x1f }, // V
        { 0x3f, 0x40, 0x38, 0x40, 0x3f }, // W
        { 0x63, 0x14, 0x08, 0x14, 0x63 }, // X
        { 0x07, 0x08, 0x70, 0x08, 0x07 }, // Y
        { 0x61, 0x51, 0x49, 0x45, 0x43 }, // Z
        { 0x00, 0x7f, 0x41, 0x41, 0x00 }, // [
        { 0x02, 0x04, 0x08, 0x10, 0x20 }, // "\"
        { 0x00, 0x41, 0x41, 0x7f, 0x00 }, // ]
        { 0x04, 0x02, 0x01, 0x02, 0x04 }, // ^
        { 0x40, 0x40, 0x40, 0x40, 0x40 }, // _
        { 0x00, 0x01, 0x02, 0x04, 0x00 }, // `
        { 0x20, 0x54, 0x54, 0x54, 0x78 }, // a
        { 0x7f, 0x48, 0x44, 0x44, 0x38 }, // b
        { 0x38, 0x44, 0x44, 0x44, 0x20 }, // c
        { 0x38, 0x44, 0x44, 0x48, 0x7f }, // d
        { 0x38, 0x54, 0x54, 0x54, 0x18 }, // e
        { 0x08, 0x7e, 0x09, 0x01, 0x02 }, // f
        { 0x0c, 0x52, 0x52, 0x52, 0x3e }, // g
        { 0x7f, 0x08, 0x04, 0x04, 0x78 }, // h
        { 0x00, 0x44, 0x7d, 0x40, 0x00 }, // i
        { 0x20, 0x40, 0x44, 0x3d, 0x00 }, // j
        { 0x7f, 0x10, 0x28, 0x44, 0x00 }, // k
        { 0x00, 0x41, 0x7f, 0x40, 0x00 }, // l
        { 0x7c, 0x04, 0x18, 0x04, 0x78 }, // m
        { 0x7c, 0x08, 0x04, 0x04, 0x78 }, // n
        { 0x38, 0x44, 0x44, 0x44, 0x38 }, // o
        { 0x7c, 0x14, 0x14, 0x14, 0x08 }, // p
        { 0x08, 0x14, 0x14, 0x18, 0x7c }, // q
        { 0x7c, 0x08, 0x04, 0x04, 0x08 }, // r
        { 0x48, 0x54, 0x54, 0x54, 0x20 }, // s
        { 0x04, 0x3f, 0x44, 0x40, 0x20 }, // t
        { 0x3c, 0x40, 0x40, 0x20, 0x7c }, // u
        { 0x1c, 0x20, 0x40, 0x20, 0x1c }, // v
        { 0x3c, 0x40, 0x30, 0x40, 0x3c }, // w
        { 0x44, 0x28, 0x10, 0x28, 0x44 }, // x
        { 0x0c, 0x50, 0x50, 0x50, 0x3c }, // y
        { 0x44, 0x64, 0x54, 0x4c, 0x44 }, // z
        { 0x00, 0x08, 0x36, 0x41, 0x00 }, // {
        { 0x00, 0x00, 0x7f, 0x00, 0x00 }, // |
        { 0x00, 0x41, 0x36, 0x08, 0x00 }, // }
        { 0x02, 0x01, 0x02, 0x04, 0x02 }, // ~
        { 0x00, 0x00, 0x00, 0x00, 0x00 },
    };

/*PRIVATE VARIABLES*/
static volatile int T;
static bool oledOn = false;
static uint8_t hexDigits[] = {0x30,0x31,0x32,0x33,0x34,0x35,0x36,0x37,0x38,0x39,0x41,0x42,0x43,0x44,0x45,0x46};
static Cursor cursor;

/*FUNCTION DEFINITIONS*/

/*I2C function definitions*/

static void i2cDelay(void) {
	T = 0;
}

static uint8_t i2cMasterWrite(uint8_t sByte) {
	uint8_t b = 0;
    uint8_t i = 8;
    while (i > 0) {
        --i;
        b = (sByte>>i) & 0x1;  // Shift each bit
        if (b == 0) {
            SDA_CLEAR();
        }
        else {
            SDA_SET();
        }
        i2cDelay();
        SCL_SET();            // Clock High
        i2cDelay();
        SCL_CLEAR();          // Clock Low
	}
	
	SDA_SET();                // Switch to Input
    SDA_MAKEINPUT();
    i2cDelay();
    SCL_SET();                // Clock High
    i2cDelay();
    b = SDA_GET();
    SCL_CLEAR();              // Clock Low
    i2cDelay();
    SDA_MAKEOUTPUT();
    SDA_CLEAR();              // Switch to Output
    
    return b;
}

static void i2cStart(void) {
    SDA_SET();
    SCL_SET();
    i2cDelay();
    SDA_CLEAR();
    i2cDelay();
    SCL_CLEAR();
    i2cDelay();
}

static void i2cStop(void) {
	SDA_CLEAR();  
    SCL_SET();
    i2cDelay();
    SDA_SET();
}

static void i2cWrite(uint8_t devAddr, uint8_t regAddr, uint8_t regData) {
	i2cStart();                          // Send the Start Bit
    
    i2cMasterWrite((devAddr<<1)|0);      // Write - Send the Device Address                                
    i2cMasterWrite(regAddr);             // Write Register Address
    i2cMasterWrite(regData);             // Write Register Data
    
    i2cStop();                           // Send the Stop Bit
}

/*Private oLed function definitions*/

static void entireOn( bool ignore ) {
	if (ignore) {
        sendByte(COMMAND, 0xA5);
    }
    else {
        sendByte(COMMAND, 0xA4);
    }
}

static void masterConfiguration( uint8_t select ) {
	sendByte(COMMAND, 0xAD);
    sendByte(COMMAND, 0x8E|select);
}

static void sendNop( void ) {
	sendByte( COMMAND, 0xE3 );
}

static void sendByte( DCselect DC, uint8_t sByte ) {
	if (DC == DATA) {
        i2cWrite(DEVADDRESS, DATACONTROL, sByte);
    }
    else if (DC == COMMAND) {
        i2cWrite(DEVADDRESS, COMMANDCONTROL, sByte);
    }
    return;
}

static void setAreaColorMode( bool color, bool lowPower ) {
	uint8_t setup = 0;
    if (color) {
        setup += 0x30;
    }
    if (lowPower) {
        setup += 0x05;
    }

    sendByte( COMMAND, 0xD8 );
    sendByte( COMMAND, setup );
}

static void setBankColor( uint8_t bankHalf, uint8_t color1, uint8_t color2, uint8_t color3, uint8_t color4, uint8_t color5, uint8_t color6, uint8_t color7, uint8_t color8, uint8_t color9, uint8_t color10, uint8_t color11, uint8_t color12, uint8_t color13, uint8_t color14, uint8_t color15, uint8_t color16) {
	uint8_t set1;
    uint8_t set2;
    uint8_t set3;
    uint8_t set4;
    set1 = color1 + (color2<<2) + (color3<<4) + (color4<<6);
    set2 = color5 + (color6<<2) + (color7<<4) + (color8<<6);
    set3 = color9 + (color10<<2) + (color11<<4) + (color12<<6);
    set4 = color13 + (color14<<2) + (color15<<4) + (color16<<6);
    if (bankHalf == 1) {
        sendByte(COMMAND, 92);
        sendByte(COMMAND, set1);
        sendByte(COMMAND, set2);
        sendByte(COMMAND, set3);
        sendByte(COMMAND, set4);
    }
    else {
        sendByte(COMMAND, 93);
        sendByte(COMMAND, set1);
        sendByte(COMMAND, set2);
        sendByte(COMMAND, set3);
        sendByte(COMMAND, set4);
    }
}

static void setBrightness( uint8_t brightness ) {
	sendByte(COMMAND, 0x82);
    sendByte(COMMAND, brightness);
}

static void setClock( uint8_t frequency, uint8_t divideRatio ) {
	uint8_t val = 0;
    val += (frequency<<4) & 0xF0;
    val += divideRatio & 0x0F;
    sendByte(COMMAND,0xD5);
    sendByte(COMMAND,val);
}

static void setColumnAddress( uint8_t startAddr, uint8_t endAddr) {
	sendByte(COMMAND, 0x21);
    sendByte(COMMAND, startAddr);
    sendByte(COMMAND, endAddr);
}

static void setComPinConfig( uint8_t cpConfig ) {
	uint8_t val = 0x02;
    val |= cpConfig;
    sendByte( COMMAND, 0xDA );
    sendByte( COMMAND, val );
}

static void setComRemap( bool remap ) {
	if (!remap) {
        sendByte(COMMAND, 0xC0);
    }
    else {
        sendByte(COMMAND, 0xC8);
    }
}

static void setContrastControl( uint8_t contrast ) {
	sendByte(COMMAND, 0x81);
    sendByte(COMMAND, contrast);
}

static void setDisplayOffset( uint8_t shift ) {
	sendByte(COMMAND, 0xD3);
    sendByte(COMMAND, shift);
}

static void setLookUpTable( uint8_t pulse0, uint8_t pulseA, uint8_t pulseB, uint8_t pulseC ) {
	sendByte(COMMAND, 0x91);
    sendByte(COMMAND, pulse0);
    sendByte(COMMAND, pulseA);
    sendByte(COMMAND, pulseB);
    sendByte(COMMAND, pulseC);
}

static void setMemAddressMode( uint8_t mode ) {
	sendByte(COMMAND, 0x20);
    sendByte(COMMAND, mode);
}

static void setMultiplexRatio( uint8_t ratio ) {
	sendByte(COMMAND, 0xA8);
    sendByte(COMMAND, ratio);
}

static void setNormal( bool normal ) {
	if (normal) {
        sendByte(COMMAND, 0xA6);
    }
    else {
        sendByte(COMMAND, 0xA7);
    }
}

static void setPageAddress( uint8_t startAddr, uint8_t endAddr) {
	sendByte(COMMAND, 0x22);
    sendByte(COMMAND, startAddr);
    sendByte(COMMAND, endAddr);
}

static void setPageStartAddress( uint8_t start ) {
	sendByte(COMMAND, 0xB0|start);
}

static void setPrecharge( uint8_t phase1, uint8_t phase2 ) {
	uint8_t period = 0;
    period += (phase1 & 0x0F);
    period += (phase2 & 0xF0);
    sendByte( COMMAND, 0xD9 );
    sendByte( COMMAND, period );
}

static void setSegmentRemap( uint8_t select ) {
	sendByte(COMMAND, select|0xA0);
}

static void setStartColumn( uint8_t start ) {
	sendByte( COMMAND, 0x00+start%16);
    sendByte( COMMAND, 0x10+start/16);
}

static void setStartLine( uint8_t line ) {
	sendByte(COMMAND, 0x40|line);
}

static void setVCOMH( uint8_t level ) {
	sendByte( COMMAND, 0xDB );
    sendByte( COMMAND, level );
}

/*Public oLed function definitions*/

void OLED_clear(void) {
	uint8_t i;
	for (i = 0; i < 8; i++) {
		uint8_t j;
        setPageStartAddress(i);
        setStartColumn( 0x00 );
        
        for (j = 0; j < 132; j++) {
            sendByte( DATA, 0x00 );
        }
    }
}

void OLED_init(void) {
	SCL_MAKEOUTPUT();
    SCL_SETPULLUP();
    SCL_SET();
    SDA_MAKEOUTPUT();
    SDA_SETPULLUP();
    SDA_SET();
    RESET_MAKEOUTPUT();
    RESET_SET();
    cursor.line = cursor.column = 0;
	OLED_on(false);
    setClock( 1, 0 );
    setMultiplexRatio( 0x1F );
    setDisplayOffset( 0x00 );
    setStartLine( 0x00 );
    masterConfiguration( 0x00 );
    setAreaColorMode( false, true );
    setMemAddressMode( 0x02 );
    setSegmentRemap( 0x01 );
    setComRemap( true );
    setComPinConfig( 0x10 );
    setLookUpTable( 0x3F, 0x3F, 0x3F, 0x3F );
    setContrastControl( 0x0A );
    setBrightness( 0x0A );
    setPrecharge( 0x02, 0xD0 );
    setVCOMH( 0x08 );
    entireOn( false );
    setNormal( true );
    OLED_clear( );
    OLED_on( true );
}

void OLED_on(bool on) {
	if (on) {
        sendByte( COMMAND, 0xAF );
        oledOn = true;
    }
    else {
        sendByte( COMMAND, 0xAE );
        oledOn = false;
    }
    return;
}

void OLED_reset(void) {
	RESET_CLEAR();
    i2cDelay();
    i2cDelay();
    RESET_SET();
}

void OLED_setCursor( uint8_t line, uint8_t column ) {
	cursor.line = line;
    cursor.column = column;
}

bool OLED_status(void) {
	return oledOn;
}

void OLED_writeChar(char c) {
	uint8_t i;
	if (cursor.column + 10 > 127) {
        setStartColumn(4);
        if (cursor.line + 1 <= 3) {
            setPageStartAddress(cursor.line+1);
            OLED_setCursor( cursor.line+1, 0 );
        }
        else {
            OLED_clear();
            setPageStartAddress(0);
            OLED_setCursor( 0, 0 );
        }
    }
    else {
        setPageStartAddress(cursor.line);
        setStartColumn(cursor.column+4);
    }
    
    if (c == '\n') {
        cursor.column = 0;
        cursor.line = (cursor.line < 3) ? (cursor.line + 1) : 0;
        if (cursor.line == 0) {
            OLED_clear();
        }
        return;
    }
    
    if ((c & 0x7F) < (' ')) {
        c = 0;
    }
    else {
        c -= (' ');
    }
    
    for (i = 0; i < 5; i++) {
        sendByte( DATA, font[(uint8_t)c][i] );
    }
    
    sendByte( DATA, 0x00 );
    
    OLED_setCursor( cursor.line, cursor.column+6 );
}

void OLED_writeHex(uint32_t num) {
	OLED_writeChar('0');
    OLED_writeChar('x');
    OLED_writeUInt(num, 16);
}

void OLED_writeInt(int32_t num) {
	uint8_t buf[10];
    uint8_t bufIndex = 10;
    
    // if the number is less than 0 then it is signed.
    char sign = (num < 0) ? '-' : 0;
    
    if (sign != 0) {

        OLED_writeChar( sign );
        
    }
    
    // starting at the end of the string, add digits.
    for (;;) {
        int8_t idx = (int8_t) (num % 10);
        buf[--bufIndex] = (uint8_t)(hexDigits[(uint8_t)(idx < 0 ? -idx : idx)]);
        num /= 10;
    	if (!num) {
    		break;
    	}
    }
    
    // starting at the most significant digit, display them.
    for (; bufIndex < 10; bufIndex++) {

        OLED_writeChar( buf[bufIndex] );
        
    }
}

void OLED_writeLogo(void) {
	setPageStartAddress(0);
	setStartColumn(14);
	OLED_setCursor(0, 14);
	sendByte(DATA, 0xFC);
	sendByte(DATA, 0xFC);
	sendByte(DATA, 0xFC);
	sendByte(DATA, 0xFC);
	sendByte(DATA, 0x00);
	sendByte(DATA, 0x80);
	sendByte(DATA, 0x80);
	sendByte(DATA, 0x80);
	sendByte(DATA, 0x80);
	sendByte(DATA, 0x00);
	setPageStartAddress(1);
	setStartColumn(9);
	sendByte(DATA, 0xFC);
	sendByte(DATA, 0xFC);
	sendByte(DATA, 0xFC);
	sendByte(DATA, 0xFC);
	sendByte(DATA, 0x00);
	sendByte(DATA, 0xFF);
	sendByte(DATA, 0xFF);
	sendByte(DATA, 0xFF);
	sendByte(DATA, 0xFF);
	sendByte(DATA, 0x00);
	sendByte(DATA, 0xFF);
	sendByte(DATA, 0xFF);
	sendByte(DATA, 0xFF);
	sendByte(DATA, 0xFF);
	sendByte(DATA, 0x00);
	sendByte(DATA, 0xFF);
	sendByte(DATA, 0xFF);
	sendByte(DATA, 0xFF);
	sendByte(DATA, 0xFF);
	sendByte(DATA, 0x00);
	sendByte(DATA, 0xFE);
	sendByte(DATA, 0xFE);
	sendByte(DATA, 0xFE);
	sendByte(DATA, 0xFE);
	sendByte(DATA, 0x00);
	
	OLED_writeString("emmoco", 2, 0);
}

void OLED_writeString(char* s, uint8_t line, uint8_t column) {
	char* ptr = (char*)s;
    char temp;
    uint8_t i;
    setPageStartAddress(line);
    setStartColumn(column+4);
    OLED_setCursor(line, column);
    // Loop while there are more characters in the string.
    while (*ptr != 0) {
        // Get a working copy of the current character and convert to an index 
        // into the character bit-map array.
        temp = *ptr++ & 0x7F;
        if (temp < (' ')) {
            temp = 0;
        }
        else {
            temp -= (' ');
        }

        for (i = 0; i < 5; i++) {
            sendByte( DATA, font[(uint8_t)temp][i] );
        }
    
        sendByte( DATA, 0x00 );

        // Return if the right side of the display has been reached.
        if ( (cursor.column+10) > 127) {
            return;
        }
        else {
            OLED_setCursor(cursor.line, cursor.column+6);
        }
        
    }
}

void OLED_writeUInt(uint32_t num, uint8_t base) {
	uint8_t buf[10];
    uint8_t bufIndex = 10;
    
    // starting at the end of the string, add digits.
    for (;;) {
        uint8_t idx = (uint8_t) (num % base);
        buf[--bufIndex] = (uint8_t)(hexDigits[idx]);
        num /= base;
    	if (!num) {
    		break;
    	}
    }
    
    // starting at the most significant digit, display them.
    for (; bufIndex < 10; bufIndex++) {
    
        OLED_writeChar( buf[bufIndex] );
        
    }
}
