#ifndef _BJSTATE_H_
#define _BJSTATE_H_

class BJState
{
	public:
	short actionTaken;
	short bet;
	short contrib;
	short dealerUp;
	short ncards;
	short cards[16];
	short sum;
	short flags;
    bool terminal;
	BJState *parent;
	BJState *child1;
	BJState *child2;

	__device__ BJState();
};

#endif
