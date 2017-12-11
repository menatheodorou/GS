#ifndef Em_Console_H_
#define Em_Console_H_

#include <stdint.h>

void Em_Console_init(void);
void Em_Console_put8(uint8_t d);
void Em_Console_put16(uint16_t d);
void Em_Console_put32(uint32_t d);
void Em_Console_putc(char ch);
void Em_Console_puts(char* s);

#define PRS(s)  (Em_Console_puts(s))
#define PR8(l,v)    (Em_Console_puts(l),Em_Console_puts(" = "),Em_Console_put8(v),Em_Console_puts("\n"))
#define PR16(l,v)   (Em_Console_puts(l),Em_Console_puts(" = "),Em_Console_put16(v),Em_Console_puts("\n"))
#define PR32(l,v)   (Em_Console_puts(l),Em_Console_puts(" = "),Em_Console_put32(v),Em_Console_puts("\n"))

#endif /* Em_Console_H_ */
