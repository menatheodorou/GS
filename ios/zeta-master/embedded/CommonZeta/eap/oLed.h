
#include <stdbool.h>
#include <stdint.h>

/* Public function prototypes */

void OLED_clear(void);
void OLED_init(void);
void OLED_on(bool on);
void OLED_reset(void);
void OLED_setCursor( uint8_t line, uint8_t column );
bool OLED_status(void);
void OLED_writeChar(char c);
void OLED_writeHex(uint32_t num);
void OLED_writeInt(int32_t num);
void OLED_writeLogo();
void OLED_writeString(char* s, uint8_t line, uint8_t column);
void OLED_writeUInt(uint32_t num, uint8_t base);
