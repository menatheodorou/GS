#include <stdint.h>
#include <msp430.h>

#define LPwM0 LPM0_bits
#define LPwM1 LPM1_bits
#define LPwM2 LPM2_bits
#define LPwM3 LPM3_bits
#define LPwM4 LPM4_bits

#define LPwM1_ONEXIT() 	_BIC_SR_IRQ(SCG1+OSCOFF)
#define LPwM4_ONEXIT()	_BIS_SR_IRQ(LPwM4)
						

void enterLowPowerMode(uint8_t mode);
