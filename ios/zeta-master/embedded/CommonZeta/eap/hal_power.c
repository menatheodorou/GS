#include <msp430.h>
#include "hal_power.h"

void enterLowPowerMode(uint8_t mode) {
	if ((mode == LPwM0)||(mode == LPwM1)||(mode == LPwM2)||(mode == LPwM3)||(mode == LPwM4)) {
		__bis_status_register(mode);
	}
}
