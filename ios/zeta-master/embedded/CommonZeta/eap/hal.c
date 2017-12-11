#include <msp430.h>
#include "hal.h"

/*Private function prototypes*/
static void GPIO_init(void);
static void BCSplus_init(void);
static void System_init(void);
static void WDTplus_init(void);

void HAL_init(void)
{
    /* Stop watchdog timer from timing out during initial start-up. */
    WDTCTL = WDTPW + WDTHOLD;

    /* initialize Config for the MSP430 GPIO */
    GPIO_init();

    /* initialize Config for the MSP430 2xx family clock systems (BCS) */
    BCSplus_init();

    /* initialize Config for the MSP430 System Registers */
    System_init();

    /* initialize Config for the MSP430 WDT+ */
    WDTplus_init();

}

/*
 *  ======== GPIO_init ========
 *  Initialize MSP430 General Purpose Input Output Ports
 */
static void GPIO_init(void)
{
    /* Port 1 Output Register */
    P1OUT = 0;

    /* Port 1 Port Select Register */
    P1SEL =  0;

    /* Port 1 Port Select 2 Register */
    P1SEL2 = 0;

    /* Port 1 Direction Register. */
    P1DIR = 0;

    /* Port 1 Interrupt Edge Select Register */
    P1IES = 0;

    /* Port 1 Interrupt Flag Register */
    P1IFG = 0;

    /* Port 2 Direction Register. 2540Reset & LED pins are outputs. */
    P2DIR = BIT4 + BIT5;
    
    /* Port 2 Output Register. Hold Reset line low at start to hold 2540 in reset. */
    P2OUT = 0;

    /* Port 2 Interrupt Edge Select Register */
    P2IES = 0;

    /* Port 2 Interrupt Flag Register */
    P2IFG = 0;

}

/*
 *  ======== BCSplus_init ========
 *  Initialize MSP430 Basic Clock System
 */
static void BCSplus_init(void)
{
    /* 
     * Basic Clock System Control 2
     * 
     * SELM_0 -- DCOCLK
     * DIVM_0 -- Divide by 1
     * ~SELS -- DCOCLK
     * DIVS_0 -- Divide by 1
     * ~DCOR -- DCO uses internal resistor
     * 
     * Note: ~<BIT> indicates that <BIT> has value zero
     */
    BCSCTL2 = SELM_0 + DIVM_0 + DIVS_0;

    if (CALBC1_1MHZ != 0xFF) {
        /* Follow recommended flow. First, clear all DCOx and MODx bits. Then
         * apply new RSELx values. Finally, apply new DCOx and MODx bit values.
         */
        DCOCTL = 0x00;
        BCSCTL1 = CALBC1_1MHZ;      /* Set DCO to 1MHz */
        DCOCTL = CALDCO_1MHZ;
    }

    /* 
     * Basic Clock System Control 1
     * 
     * XT2OFF -- Disable XT2CLK
     * ~XTS -- Low Frequency
     * DIVA_0 -- Divide by 1
     * 
     * Note: ~XTS indicates that XTS has value zero
     */
    BCSCTL1 |= XT2OFF + DIVA_0;

    /* 
     * Basic Clock System Control 3
     * 
     * XT2S_0 -- 0.4 - 1 MHz
     * LFXT1S_2 -- If XTS = 0, XT1 = VLOCLK ; If XTS = 1, XT1 = 3 - 16-MHz crystal or resonator
     * XCAP_1 -- ~6 pF
     */
    BCSCTL3 = XT2S_0 + LFXT1S_2 + XCAP_1;
}

/*
 *  ======== System_init ========
 *  Initialize MSP430 Status Register
 */
static void System_init(void)
{

}

/*
 *  ======== WDTplus_init ========
 *  Initialize MSP430 Watchdog Timer+
 */
static void WDTplus_init(void)
{
    /* 
     * WDTCTL, Watchdog Timer+ Register
     * 
     * WDTHOLD -- Watchdog timer+ is stopped
     * ~WDTNMIES -- NMI on rising edge
     * ~WDTNMI -- Reset function
     * ~WDTTMSEL -- Watchdog mode
     * ~WDTCNTCL -- No action
     * ~WDTSSEL -- SMCLK
     * ~WDTIS0 -- Watchdog clock source bit0 disabled
     * ~WDTIS1 -- Watchdog clock source bit1 disabled
     * 
     * Note: ~<BIT> indicates that <BIT> has value zero
     */
    WDTCTL = WDTPW + WDTHOLD;
    
}
