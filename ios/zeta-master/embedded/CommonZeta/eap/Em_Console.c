#include <stdbool.h>
#include <stdint.h>
#include <msp430.h>

#include "Em_Console.h"

#define Em_Console_BITIME 50
#define Em_Console_HEXDIGS "0123456789ABCDEF"

bool Em_Console_interrupted;

void Em_Console_init(void) {
    
    Em_Console_interrupted = 0;
    
    /* Port 1 Output Register */
    P1OUT = 0;

    /* Set Port 1 bit 5 to primary peripheral mode */
    P1SEL |= BIT5;

    /* Set port 1 bit 5 to output */
    P1DIR |= BIT5;
    
    /* 
     * TA0CCTL0, Capture/Compare Control Register 0
     * 
     * CM_0 -- No Capture
     * CCIS_0 -- CCIxA
     * ~SCS -- Asynchronous Capture
     * ~SCCI -- Latched capture signal (read)
     * ~CAP -- Compare mode
     * OUTMOD_0 -- PWM output mode: 0 - OUT bit value
    */
    
    TA0CCTL0 = CM_0 + CCIS_0 + OUTMOD_0 + CCIE + OUT;

    /* TA0CCR0, Timer_A Capture/Compare Register 0 */
    TA0CCR0 = 1200;

    /* 
     * TA0CTL, Timer_A3 Control Register
     * 
     * TASSEL_2 -- SMCLK
     * ID_1 -- Divider - /2
     * MC_2 -- Continuous Mode
     */
    TA0CTL = TASSEL_2 + ID_1 + MC_2;
    
    Em_Console_putc(0);
    Em_Console_putc(8);
}

void Em_Console_putc(char ch) {
    uint8_t bitCnt = 0xA;                    // Load Bit counter, 8data + ST/SP
    uint16_t txByte = (uint16_t)ch | 0x100;  // Add mark stop bit to txByte
    txByte = txByte << 1;                    // Add space start bit

    CCR0 = TAR + Em_Console_BITIME;        // Some time till first bit
    CCTL0 = OUTMOD0 + CCIE;                 // TXD = mark = idle
    for (;;) {
        while (!(TA0CCTL0 & CCIFG) && Em_Console_interrupted == 0) {
        }
        Em_Console_interrupted = 0;
        TA0CCTL0 &= ~CCIFG;
        TA0CCR0 += (Em_Console_BITIME);    // Schedule next interrupt
        
        if (bitCnt-- == 0){
            TA0CCTL0 &= ~CCIE;
            break;
        }
        else {
            if (txByte & 0x01) {
                CCTL0 &= ~OUTMOD2;          // TX Mark
            }
            else {
                CCTL0 |= OUTMOD2;           // TX Space
            }
            txByte = txByte >> 1;
        }
    }
}

void Em_Console_put8(uint8_t d) {
    Em_Console_putc(Em_Console_HEXDIGS[(d >> 4) & 0xF]);
    Em_Console_putc(Em_Console_HEXDIGS[d & 0xF]);
}

void Em_Console_put16(uint16_t d) {
    Em_Console_putc(Em_Console_HEXDIGS[(d >> 12) & 0xF]);
    Em_Console_putc(Em_Console_HEXDIGS[(d >> 8) & 0xF]);
    Em_Console_putc(Em_Console_HEXDIGS[(d >> 4) & 0xF]);
    Em_Console_putc(Em_Console_HEXDIGS[d & 0xF]);
}

void Em_Console_put32(uint32_t d) {
    Em_Console_putc(Em_Console_HEXDIGS[(d >> 28) & 0xF]);
    Em_Console_putc(Em_Console_HEXDIGS[(d >> 24) & 0xF]);
    Em_Console_putc(Em_Console_HEXDIGS[(d >> 20) & 0xF]);
    Em_Console_putc(Em_Console_HEXDIGS[(d >> 16) & 0xF]);
    Em_Console_putc(Em_Console_HEXDIGS[(d >> 12) & 0xF]);
    Em_Console_putc(Em_Console_HEXDIGS[(d >> 8) & 0xF]);
    Em_Console_putc(Em_Console_HEXDIGS[(d >> 4) & 0xF]);
    Em_Console_putc(Em_Console_HEXDIGS[d & 0xF]);
}

void Em_Console_puts(char* s) {
    char c;
    while ((c = *s++)) {
        if (c == '\n') {
            Em_Console_putc('\r');
        }
        Em_Console_putc(c);
    }
}

__attribute__((interrupt(TIMER0_A0_VECTOR)))
void Em_Console_isr(void) {
    Em_Console_interrupted = 1;
}
