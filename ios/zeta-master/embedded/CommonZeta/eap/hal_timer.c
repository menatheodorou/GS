#include <msp430.h>
#include "hal_timer.h"
#include "hal_power.h"

/*
 * ======== Local Function Declarations ========
 */

void Timer0_A3_init(int period);
uint8_t Timer0_A3_isRunning(void);
void Timer0_A3_start(void);
void Timer0_A3_stop(void);

void Timer1_A3_init(int period);
uint8_t Timer1_A3_isRunning(void);
void Timer1_A3_start(void);
void Timer1_A3_stop(void);

/*
 * ======== Public Function Definitions ========
 */

void HalTimerInit(uint8_t timer, int period)
{
	if (timer == TIMER0) {
		Timer0_A3_init(period);
	}
	else if (timer == TIMER1) {
		Timer1_A3_init(period);
	}
}

uint8_t HalTimerIsRunning(uint8_t timer)
{
	uint8_t running = 0;
	if (timer == TIMER0) {
		running = Timer0_A3_isRunning();
	}
	else if (timer == TIMER1) {
		running = Timer1_A3_isRunning();
	}
	return running;
}

void HalTimerStart(uint8_t timer)
{
	if (timer == TIMER0) {
		Timer0_A3_start();
	}
	else if (timer == TIMER1) {
		Timer1_A3_start();
	}
}

void HalTimerStop(uint8_t timer)
{
	if (timer == TIMER0) {
		Timer0_A3_stop();
	}
	else if (timer == TIMER1) {
		Timer1_A3_stop();
	}
}

/*
 * ======== Private Function Definitions ========
 */

/*
 *  ======== Timer0_A3_init ========
 *  Initialize MSP430 Timer1_A3 timer
 *  The units of period is milliseconds.
 */
void Timer0_A3_init(int period)
{
    /* 
     * TA0CCTL0, Capture/Compare Control Register 0
     * 
     * CM_0 -- No Capture
     * CCIS_0 -- CCIxA
     * ~SCS -- Asynchronous Capture
     * ~SCCI -- Latched capture signal (read)
     * ~CAP -- Compare mode
     * OUTMOD_0 -- PWM output mode: 0 - OUT bit value
     * 
     * Note: ~<BIT> indicates that <BIT> has value zero
     */
    TA0CCTL0 = CM_0 + CCIS_0 + OUTMOD_0 + CCIE;

    /* TA0CCR0, Timer_A Capture/Compare Register 0 */
    TA0CCR0 = ((12000*period)/1000);

    /* 
     * TA0CTL, Timer_A3 Control Register
     * 
     * TASSEL_1 -- ACLK
     * ID_0 -- Divider - /1
     * MC_0 -- Off
     */
    TA0CTL = TASSEL_1 + ID_0 + MC_0;
}

/*
 *  ======== Timer0_A3_isRunning ========
 *
 */
uint8_t Timer0_A3_isRunning(void)
{
	if (TA0CTL & MC_1) {
		return 1;
	}
	return 0;
}

/*
 *  ======== Timer0_A3_start ========
 *
 */
void Timer0_A3_start(void)
{
	TA0R = 0;
	TA0CCTL0 &= ~(BIT0);
	TA0CCTL0 |= BIT4;
	TA0CTL |= MC_1;
	
}

/*
 *  ======== Timer0_A3_stop ========
 *
 */
void Timer0_A3_stop(void)
{
	TA0R = 0;
	TA0CCTL0 &= ~(BIT4);
	TA0CCTL0 &= ~(BIT0);
	TA0CTL &= ~(MC_1);
	
}

/*
 *  ======== Timer1_A3_init ========
 *  Initialize MSP430 Timer1_A3 timer
 */
void Timer1_A3_init(int period)
{
    /* 
     * TA1CCTL0, Capture/Compare Control Register 0
     * 
     * CM_0 -- No Capture
     * CCIS_0 -- CCIxA
     * ~SCS -- Asynchronous Capture
     * ~SCCI -- Latched capture signal (read)
     * ~CAP -- Compare mode
     * OUTMOD_0 -- PWM output mode: 0 - OUT bit value
     * 
     * Note: ~<BIT> indicates that <BIT> has value zero
     */
    TA1CCTL0 = CM_0 + CCIS_0 + OUTMOD_0 + CCIE;

    /* TA1CCR0, Timer_A Capture/Compare Register 0 */
    TA1CCR0 = ((12000*period)/1000);

    /* 
     * TA1CTL, Timer_A3 Control Register
     * 
     * TASSEL_1 -- ACLK
     * ID_0 -- Divider - /1
     * MC_0 -- Off
     */
    TA1CTL = TASSEL_1 + ID_0 + MC_0;
}

/*
 *  ======== Timer1_A3_isRunning ========
 *
 */
uint8_t Timer1_A3_isRunning(void)
{
	if (TA1CTL & MC_1) {
		return 1;
	}
	return 0;
}

/*
 *  ======== Timer1_A3_start ========
 *
 */
void Timer1_A3_start(void)
{
	TA1R = 0;
	TA1CCTL0 &= ~(BIT0);
	TA1CCTL0 |= BIT4;
	TA1CTL |= MC_1;
	
}

/*
 *  ======== Timer1_A3_stop ========
 *
 */
void Timer1_A3_stop(void)
{
	TA1R = 0;
	TA1CCTL0 &= ~(BIT4);
	TA1CCTL0 &= ~(BIT0);
	TA1CTL &= ~(MC_1);
	
}

/*
 *  ======== Timer0_A3 Interrupt Service Routine ========
 */
__attribute__((interrupt(TIMER0_A0_VECTOR)))
void TIMER0_A0_ISR_HOOK(void) {

    /* Capture Compare Register 0 ISR Hook Function Name */
	timer0_isr();
	
}

/*
 *  ======== Timer1_A3 Interrupt Service Routine ======== 
 */
__attribute__((interrupt(TIMER1_A0_VECTOR)))
void TIMER1_A0_ISR_HOOK(void)
{

	/* Capture Compare Register 0 ISR Hook Function Name */
	if (timer1_isr() == 1) {
		LPwM4_ONEXIT();
	}
}
