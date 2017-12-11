#include <msp430.h>
#include "hal_uart.h"
#include "hal_power.h"

#include <Em_Message.h>

#define MCMRTS_GET()  		((P1IN & BIT5) ? 1 : 0)
#define MCMRTS_MAKEINPUT() 	(P1DIR &= ~BIT5)
#define MCMRTS_MASK			BIT5

#define MCMCTS_MAKEOUTPUT() (P1DIR |= BIT4)
#define MCMCTS_SET()		(P1OUT |= BIT4)
#define MCMCTS_CLEAR()		(P1OUT &= ~BIT4)

unsigned char startReceive = 0;

/*
 *  ======== Em_Message_startSend ========
 *  Initiate message transmission
 */
void Em_Message_startSend() {
    uint8_t b;
    if (Em_Message_getByte(&b)) {
        UCA0TXBUF = b;
    }
}

/*
 *  ======== USCI_A0_init ========
 *  Initialize Universal Serial Communication Interface A0 UART 2xx
 */
void HalUartInit(void)
{
    /* Disable USCI */
    UCA0CTL1 |= UCSWRST;

	/* Enable GPIO peripheral mode for the UART */
	P1SEL |= BIT1 + BIT2;
	P1SEL2 |= BIT1 + BIT2;
	
	/* MCM CTS must be high by default */
	MCMCTS_MAKEOUTPUT();
	MCMCTS_SET();

	/* MCM RTS input, interrupt trigger on falling edge */
	MCMRTS_MAKEINPUT();
	P1IES |= (MCMRTS_MASK);
	P1IFG &= ~(MCMRTS_MASK);
	P1IE |= (MCMRTS_MASK);

    /* 
     * Control Register 1
     * 
     * UCSSEL_2 -- SMCLK
     * ~UCRXEIE -- Erroneous characters rejected and UCAxRXIFG is not set
     * ~UCBRKIE -- Received break characters do not set UCAxRXIFG
     * ~UCDORM -- Not dormant. All received characters will set UCAxRXIFG
     * ~UCTXADDR -- Next frame transmitted is data
     * ~UCTXBRK -- Next frame transmitted is not a break
     * UCSWRST -- Enabled. USCI logic held in reset state
     * 
     * Note: ~<BIT> indicates that <BIT> has value zero
     */
    UCA0CTL1 = UCSSEL_2 + UCSWRST;
    
    /* 
     * Modulation Control Register
     * 
     * UCBRF_0 -- First stage 0
     * UCBRS_6 -- Second stage 6
     * ~UCOS16 -- Disabled
     * 
     * Note: ~UCOS16 indicates that UCOS16 has value zero
     */
    UCA0MCTL = UCBRF_0 + UCBRS_6;
    
    /* Baud rate control register 0 */
    UCA0BR0 = 8;
    
    /* Enable USCI */
    UCA0CTL1 &= ~UCSWRST;
    
    /* 
     * IFG2, Interrupt Flag Register 2
     * 
     * ~UCB0TXIFG -- No interrupt pending
     * ~UCB0RXIFG -- No interrupt pending
     * ~UCA0TXIFG -- No interrupt pending
     * UCA0RXIFG -- Interrupt pending
     * 
     * Note: ~<BIT> indicates that <BIT> has value zero
     */
    IFG2 &= ~(UCA0RXIFG);

    /* 
     * IE2, Interrupt Enable Register 2
     * 
     * ~UCB0TXIE -- Interrupt disabled
     * ~UCB0RXIE -- Interrupt disabled
     * ~UCA0TXIE -- Interrupt disabled
     * UCA0RXIE -- Interrupt enabled
     * 
     * Note: ~<BIT> indicates that <BIT> has value zero
     */
    IE2 |= UCA0RXIE;
}

void HalUartStartReceive(void)
{
	startReceive = 1;
}

void HalUartStopReceive(void)
{
	startReceive = 0;
}

/*
 *  ======== USCI A0/B0 RX Interrupt Handler Generation ========
 */
__attribute__((interrupt(USCIAB0RX_VECTOR)))
void USCI0RX_ISR_HOOK(void)
{
	uint8_t b = UCA0RXBUF;
	
	if (Em_Message_addByte(b)) {
		Em_Message_dispatch();
	}
	
	/* Acknowledge byte received only if startReceive has been set*/
	if (startReceive == 1) {
		MCMCTS_CLEAR();
		MCMCTS_SET();
	}

	LPwM1_ONEXIT();
}

__attribute__((interrupt(PORT1_VECTOR)))
void PORT1_ISR_HOOK(void)
{
	if (P1IFG & MCMRTS_MASK) {
		uint8_t b;
        if (Em_Message_getByte(&b)) {
            UCA0TXBUF = b;
        }
        else {
        	if (TransmitDone()) {
        		LPwM4_ONEXIT();
        	}
        }
		P1IFG &= ~(MCMRTS_MASK);			// Clear the interrupt
	}
}

uint8_t Em_Message_lock() {
    uint8_t key;
    asm ("MOV r2, %0": "=r" (key));
    key &= 0x8;
    asm ("DINT");
    return key;
}

void Em_Message_unlock(uint8_t key) {
    if (key) {
        asm ("EINT");
    }
    else {
        asm ("DINT");
    }
}
