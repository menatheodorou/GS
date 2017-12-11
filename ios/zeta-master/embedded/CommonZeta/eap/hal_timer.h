#include <stdint.h>

#define TIMER0 0
#define TIMER1 1

/* Function Prototypes */
void HalTimerInit(uint8_t timer, int period);
uint8_t HalTimerIsRunning(uint8_t timer);
void HalTimerStart(uint8_t timer);
void HalTimerStop(uint8_t timer);

/* Interrupt Function Prototypes */
extern void timer0_isr(void);
extern uint8_t timer1_isr(void);
