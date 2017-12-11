#include <stdint.h>

void HalUartInit(void);
void HalUartStartReceive(void);
void HalUartStopReceive(void);

extern uint8_t TransmitDone(void);
