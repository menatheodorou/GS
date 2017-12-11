#include "busywait.h"

static volatile int T;

void wait(int i) {
	int j;
	for (j = 0; j < i; j++) {
		T = 10;
	}
}