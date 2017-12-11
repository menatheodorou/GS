/*
 * ======== Standard MSP430 includes ========
 */

#include <msp430.h>

/*
 * ======== Peripheral related includes ========
 */

#include <busywait.h>
#include <hal.h>
#include <hal_power.h>
#include <hal_uart.h>
#include <hal_timer.h>

/*
 * ======== Emmoco framework includes ========
 */

#include <GripAndShoot.h>

/*
 * ======== Application internals ========
 */

/************************
 * LED Operation Macros *
 ************************/
 
#define LED_ON()   		(P2OUT |= BIT5)
#define LED_OFF()  		(P2OUT &= ~BIT5)
#define LED_STATE()		(P2OUT & BIT5)
#define LED_TOGGLE()  	(P2OUT ^= BIT5)

/**************************
 * 2540 Reset Line Macros *
 **************************/
 
 #define RESET2540_ASSERT()		(P2OUT &= ~BIT4);\
 								(P2DIR |= BIT4)
 #define RESET2540_DEASSERT()	(P2OUT |= BIT4);\
                                (P2DIR &= ~(BIT4))

/********************
 * Timing Constants *
 ********************/

#define AWAKETIMEOUT	140
#define CONNECTED_DELAY 30
#define DEFAULTHOLD_DELAY 1000
#define DEFAULTREPEAT_DELAY 500
#define INIT_TIME2540	2
#define LEDTIMER_PERIOD 150

/********************
 * Button Pin Masks *
 ********************/
 
#define PICTUREMASK		BIT0
#define ZOOMINMASK		BIT2
#define ZOOMOUTMASK		BIT1

/*********
 * Types *
 *********/

typedef enum { CONNECTED, DISCONNECTED } ConnectionStatus;

typedef struct {
	uint16_t pressedTime;
	uint8_t held;
	uint16_t heldTime;
} ButtonStatus;

/*******************************
 * Local Function Declarations *
 *******************************/

void initHoldStructures(void);

/*************
 * Variables *
 *************/

// * Button Holding *
volatile uint8_t buttonHoldMask = 0;
volatile ButtonStatus pictureButtonStatus;
GripAndShoot_pictureHold_t pictureHold;

// * Button States *
volatile GripAndShoot_pictureButton_t pictureButtonState = GripAndShoot_RELEASED;
volatile GripAndShoot_zoomInButton_t zoomInButtonState = GripAndShoot_RELEASED;
volatile GripAndShoot_zoomOutButton_t zoomOutButtonState = GripAndShoot_RELEASED;

// * Connection Status *
volatile ConnectionStatus connection = DISCONNECTED;

// * Delay Counter For Led *
volatile uint8_t connectedLedToggleCount = 0;

// * Initialization Flags and Counters *
volatile uint8_t 	initDoneFlag = 0;
volatile uint16_t	initCounter = 0;

// * Power Management Flags and Counters *
volatile uint8_t awakeTimeoutCounter = 0;
volatile uint8_t deepSleepFlag = 0;
volatile uint8_t awakeTimeoutCountFlag = 1;

/*
 * ======== Interrupt Handlers ========
 */

/************************************
 * Timer Handler For Button Holding *
 ************************************/
void timer0_isr(void) {
	// Only one button at a time can be "held". Check which one.
	if (buttonHoldMask == PICTUREMASK) {
		if (P2IN & PICTUREMASK) {
			// If picture button is being pressed, check if it has reached "held" status.
			if (pictureButtonStatus.held == 0) {
				pictureButtonStatus.pressedTime += GripAndShoot_Delay_step;
				if (pictureButtonStatus.pressedTime == pictureHold.holdDelay) {
					pictureButtonStatus.held = 1;
					GripAndShoot_pictureButton_indicate();
				}
			}
			// If picture button has reached "held" status, check if next indicator should be sent.
			else {
				pictureButtonStatus.heldTime += GripAndShoot_Delay_step;
				if (pictureButtonStatus.heldTime == pictureHold.repeatDelay) {
					GripAndShoot_pictureButton_indicate();
					pictureButtonStatus.heldTime = 0;
				}
			}
		}
		// If the picture button was released stop this timer.
		else {
			HalTimerStop(TIMER0);
		}
	}
	else {
		buttonHoldMask = 0;
		HalTimerStop(TIMER0);
	}
				
}

/********************************************************
 * Timer Handler For Awake Timeout (Power Management),	*
 * Connected Led Toggling and Initialization			*
 * Return: Enter LPM4 on exit (1), no change (0)		*
 ********************************************************/
uint8_t timer1_isr(void) {
	if (initDoneFlag == 0) {
		if (++initCounter == INIT_TIME2540) {
			initDoneFlag = 1;
			LED_OFF();
			initCounter = 0;
		}
		return 0;
	}
	// awakeTimeoutCountFlag = 1 indicates that the device is awake and counting until it should go back to sleep.
	if (awakeTimeoutCountFlag == 1) {
		// If awakeTimeoutCounter = 0 the device has just woken up and the LED needs to be turned off and button
		// interrupts reenabled.
		if (awakeTimeoutCounter == 2) {
			HalUartStartReceive();
			GripAndShoot_run();
			LED_OFF();
			P2IE |= (PICTUREMASK+ZOOMINMASK+ZOOMOUTMASK);	// Enable interrupts on buttons.
		}
		awakeTimeoutCounter++;
		// Once the awake timeout has been reached the device should go back to sleep.
		if (awakeTimeoutCounter == AWAKETIMEOUT) {
				HalTimerStop(TIMER1);
				deepSleepFlag = 1;
				GripAndShoot_accept(false);
				return 0;
		}
	}
	// If the device is connected the Led should be toggled.
	if ((connection == CONNECTED)) {
		if (LED_STATE() != 0) {
			LED_TOGGLE();
		}
		connectedLedToggleCount++;
		if ((connection == CONNECTED) && (connectedLedToggleCount == CONNECTED_DELAY)) {
			LED_TOGGLE();
			connectedLedToggleCount = 0;
		}
	}
	return 0;
}

/********************************************************************
 * Button Press Handler 											*
 * Each button produces an interrupt on both the press and release.	*
 * The button state is changed to PRESSED only if the button is		*
 * still being held after debouncing.								*
 ********************************************************************/
void port2_isr(void) {
	// Debouncing.
	wait(1000);
	
	// If the device was asleep, disable button interrupts until awake.
	if (deepSleepFlag == 1) {
		deepSleepFlag = 0;
		HalUartStopReceive();
		RESET2540_ASSERT();
		LED_ON();
		GripAndShoot_reset();
		awakeTimeoutCountFlag = 1;
		awakeTimeoutCounter = 0;
		P2IE &= ~(PICTUREMASK+ZOOMINMASK+ZOOMOUTMASK);	// Disable interrupts on buttons.
		if (HalTimerIsRunning(TIMER1) == 0) {
			HalTimerStart(TIMER1);
		}
		wait(3000);
		RESET2540_DEASSERT();
		return;
	}
	
	// Check if the picture button produced and interrupt.
	if (P2IFG & PICTUREMASK) {
		
		// Check if the interrupt was on a press and if the button is still pressed after debouncing.
		if ((P2IN & PICTUREMASK)&&(~P2IES & PICTUREMASK)) {
			
			// If connected
			if ((!((P2IN & ZOOMOUTMASK)==ZOOMOUTMASK)) || (connection == CONNECTED)) {
				
				// If another button is not being "held", start the button hold timer.
				if ((HalTimerIsRunning(TIMER0) == 0)) {
					pictureButtonStatus.heldTime = 0;
					pictureButtonStatus.held = 0;
					pictureButtonStatus.pressedTime = 0;
					buttonHoldMask = PICTUREMASK;
					HalTimerStart(TIMER0);
				}
				
				// If another button was being "held", cancel that hold.
				else if (HalTimerIsRunning(TIMER0) != 0) {
					HalTimerStop(TIMER0);
				}
				
				// Change the edge trigger, set the state to pressed, and send an indicator.
				P2IES |= PICTUREMASK;			// Set edge detect to falling edge.
				pictureButtonState = GripAndShoot_PRESSED;
				GripAndShoot_pictureButton_indicate();
			}
		}
		
		// Always detect the release if the interrupt was produced no matter the current state of the pin.
		else if (P2IES & PICTUREMASK) {
			P2IES &= ~PICTUREMASK;			// Set edge detect to rising edge.
			pictureButtonState = GripAndShoot_RELEASED;
		}
		
		// Always clear the interrupt.
		P2IFG &= ~(PICTUREMASK);
	}
	
	// Check if the zoom in button produced an interrupt.
	if (P2IFG & ZOOMINMASK) {
		
		// Check if the interrupt was on a press and if the button is still pressed after debouncing.
		if ((P2IN & ZOOMINMASK)&&(~P2IES & ZOOMINMASK)) {
			
			// If any button was being "held" cancel the hold.
			if (HalTimerIsRunning(TIMER0) != 0) {
				HalTimerStop(TIMER0);
			}
			
			// Change the edge trigger, set the state to pressed, and send an indicator.
			P2IES |= ZOOMINMASK;			// Set edge detect to falling edge.
			zoomInButtonState = GripAndShoot_PRESSED;
			GripAndShoot_zoomInButton_indicate();
		}
		
		// Always detect the release if the interrupt was produced no matter the current state of the pin.
		else if (P2IES & ZOOMINMASK) {
			P2IES &= ~ZOOMINMASK;			// Set edge detect to rising edge.
			zoomInButtonState = GripAndShoot_RELEASED;
			GripAndShoot_zoomInButton_indicate();
		}
		
		// Always clear the interrupt.
		P2IFG &= ~(ZOOMINMASK);
	}
	
	// Check if the zoom out button produced an interrupt.
	if (P2IFG & ZOOMOUTMASK) {
	
		// Check if the interrupt was on a press and if the button is still pressed after debouncing.
		if ((P2IN & ZOOMOUTMASK)&&(~P2IES & ZOOMOUTMASK)) {
		
			// If another button was being "held", cancel that hold.
			if (HalTimerIsRunning(TIMER0) != 0) {
				HalTimerStop(TIMER0);
			}
			
			// If connected
			if ((!((P2IN & PICTUREMASK)==PICTUREMASK)) || (connection == CONNECTED)) {
			
				// Change the edge trigger, set the state to pressed, and send an indicator.
				P2IES |= ZOOMOUTMASK;			// Set edge detect to falling edge.
				zoomOutButtonState = GripAndShoot_PRESSED;
				GripAndShoot_zoomOutButton_indicate();
			}
		}
		
		// Always detect the release if the interrupt was produced no matter the current state of the pin.
		else if (P2IES & ZOOMOUTMASK) {
			P2IES &= ~ZOOMOUTMASK;			// Set edge detect to rising edge.
			zoomOutButtonState = GripAndShoot_RELEASED;
			GripAndShoot_zoomOutButton_indicate();
		}
		
		// Always clear the interrupt.
		P2IFG &= ~(ZOOMOUTMASK);
	}
	
	// Always reset the timeout counter to 1 to keep the device from going back to sleep while it is potentially being
	// used while not connected.
	awakeTimeoutCounter = 3;
}

/****************************************************
 * Called By The Transmit Handler To See If	Power 	*
 * State Change Is Needed After Transmit Done.		*
 ****************************************************/
uint8_t TransmitDone(void) {
	if (deepSleepFlag == 1) {
		return 1;
	}
	return 0;
}

/*
 *  ======== main ========
 */

int main(int argc, char *argv[]) {
    HAL_init();                     				// Initialize the system. Must happen before other init functions.
    HalUartInit();									// Initialize the uart for communicating with the MCM.
    HalTimerInit(TIMER0, 100);						// Initialize timer0.
    HalTimerInit(TIMER1, LEDTIMER_PERIOD);			// Initialize timer1.
    P2DIR &= ~(PICTUREMASK+ZOOMINMASK+ZOOMOUTMASK);	// Make button pins inputs.
    P2IES &= ~(PICTUREMASK+ZOOMINMASK+ZOOMOUTMASK);	// Set edge detect to rising edge.
    P2IFG &= ~(PICTUREMASK+ZOOMINMASK+ZOOMOUTMASK);	// Clear interrupt flags.
    P2IE |= (PICTUREMASK+ZOOMINMASK+ZOOMOUTMASK);	// Enable interrupts on buttons.
    LED_OFF();
    initHoldStructures();
    __enable_interrupt();           				// Set global interrupt enable.
    LED_ON();
    RESET2540_DEASSERT();
    HalTimerStart(TIMER1);
    while (initDoneFlag == 0) { }
    HalUartStartReceive();
    GripAndShoot_run();
    volatile int k = 0;
    enterLowPowerMode(LPwM1);						// Enter sleep LPM1.
    while (k == 0) {
    }
    return (0);
}

/*
 * ======== Local Function Definitions ========
 */

void initHoldStructures(void) {
	pictureHold.holdDelay = DEFAULTHOLD_DELAY;
	pictureHold.repeatDelay = DEFAULTREPEAT_DELAY;
}

/*
 *  ======== Emmoco framework callbacks ========
 */

void GripAndShoot_connectHandler(void) {
	LED_ON();
	connection = CONNECTED;
	if (HalTimerIsRunning(TIMER1) == 0) {
		HalTimerStart(TIMER1);
	}
	deepSleepFlag = 0;
	awakeTimeoutCountFlag = 0;
	awakeTimeoutCounter = 0;
}

void GripAndShoot_disconnectHandler(void) {
	LED_OFF();
	connection = DISCONNECTED;
	awakeTimeoutCountFlag = 1;
	awakeTimeoutCounter = 0;
	if (HalTimerIsRunning(TIMER1) == 0) {
		HalTimerStart(TIMER1);
	}
}

void GripAndShoot_pictureButton_fetch(GripAndShoot_pictureButton_t* const output) {
	*output = pictureButtonState;
}

void GripAndShoot_pictureHold_fetch(GripAndShoot_pictureHold_t* const output) {
	output->holdDelay = pictureHold.holdDelay;
	output->repeatDelay = pictureHold.repeatDelay;
}

void GripAndShoot_pictureHold_store(GripAndShoot_pictureHold_t* const input) {
	pictureHold.holdDelay = input->holdDelay;
	pictureHold.repeatDelay = input->repeatDelay;
}

void GripAndShoot_zoomInButton_fetch(GripAndShoot_zoomInButton_t* const output) {
	*output = zoomInButtonState;
}

void GripAndShoot_zoomOutButton_fetch(GripAndShoot_zoomOutButton_t* const output) {
	*output = zoomOutButtonState;
}

__attribute__((interrupt(PORT2_VECTOR)))
void PORT2_ISR_HOOK(void)
{

	/* Port 2 ISR Hook Function Name */
	port2_isr();

	/* Enter LPM1 on exit */
	LPwM1_ONEXIT();
}
