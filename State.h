#ifndef STATE_H
#define STATE_H

struct State {
	int bank; // required for atomicAdd() to bankroll
	char handIndex; // 0-3
	char bet;
	char action;
	char sum;
	char issoft;
	char dealer;
	char flags;
	char terminal; // 0-1
	char ncards;
	char pad[3];
	struct State *parent;
	struct State *child1;
	struct State *child2;
};
// keep 4-byte alignment
struct HandLedger {
	char nextBlock;
	char nextCard;
	char nhands;
	char pad;
	char cards[4][12];
	char ncards[4];
	char deck[52];
	struct State bjstate[32]; //4 hands of 8; 1 of 12
};

//__device__
union un {
	HandLedger *hlp;
	HandLedger h;
	int *g; // assist zeroing block
};

#define HL_SIZE (sizeof(struct HandLedger))
#define HL_ISIZE (HL_SIZE/4)

#endif // STATE_H
