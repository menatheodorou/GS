/*
 * ======== Standard MSP430 includes ========
 */

#include <msp430.h>

/*
 * ======== Peripheral related includes ========
 */

#include <hal.h>
#include <uart.h>
#include <timer.h>

/*
 * ======== Emmoco framework includes ========
 */

#include <Photo.h>

/*
 * ======== Application internals ========
 */
 
#define LED_ON()   		(P1OUT |= BIT6)
#define LED_OFF()  		(P1OUT &= ~BIT6)
#define LED_STATE()		(P1OUT & BIT6)
#define LED_TOGGLE()  	(P1OUT ^= BIT6)

#define BUTTONMASK	(1 << 0)

void timerA0_isr(void) {

}

void timerA1_isr(void) {

}

void port2_isr(void) {
	if (P2IFG & BUTTONMASK) {
		Photo_buttonPressed_indicator();
	}
	P2IFG = 0;						// Clear the interrupt
}

/*
 *  ======== main ========
 */

int main(int argc, char *argv[]) {
    HAL_init();                     // Initialize the system. Must happen before other init functions.
    USCI_A0_init();					// Initialize the uart for communicating with the MCM.
    Timer1_A3_init(1000);				// Initialize the timer.
    P2DIR &= ~(BUTTONMASK);			// Make button pin an input.
    P2IES |= (BUTTONMASK);			// Set edge detect to falling edge.
    P2IFG &= ~(BUTTONMASK);			// Clear P1.3 interrupt flag.
    P2IE |= (BUTTONMASK);			// Enable interrupts on P1.3.
    LED_OFF();
    __enable_interrupt();           // Set global interrupt enable
    volatile int k = 0;
    while (k == 0) {
    	UartDispatch();
    }
    return (0);
}

/*
 *  ======== Emmoco framework callbacks ========
 */

void Photo_connectHandler(void) {
	P1OUT |= BIT0;
}

void Photo_disconnectHandler(void) {
	P1OUT &= ~(BIT0);
}

void Photo_buttonPressed_fetch(Photo_buttonPressed_t* const output) {
	*output = 0;	
}

void Photo_buttonPressed_store(Photo_buttonPressed_t* const input) {
	
}

__attribute__((interrupt(PORT2_VECTOR)))
void PORT2_ISR_HOOK(void)
{

	/* Port 2 ISR Hook Function Name */
	port2_isr();

	/* No change in operating mode on exit */
}
