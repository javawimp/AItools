#include "bjState.h"

__device__ BJState::BJState() {
	actionTaken = bet = contrib = sum = dealerUp = 0;
	cards[0] = 0;
    flags = 0;
    terminal = false;
	parent = child1 = child2 = NULL;
}
