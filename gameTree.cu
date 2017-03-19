#include "includes.h"
#include "externs.h"
#include "bjState.h"

__device__ const char *choice[4] = {"STAND","HIT","DOUBLE","SPLIT"};
__device__ const char *cardName[14] = { "","n A"," 2"," 3"," 4"," 5"," 6"," 7","n 8"," 9"," 10"," J"," Q"," K" };

__device__ void cardString(short ncards,short *cards,char *cardbuf)
{
	cardbuf[0] = '{';
	cardbuf[1] = strcard[DENOM(cards[0])];
    for (int i=1;i<ncards;++i) {
    	cardbuf[2*i] = ',';
    	cardbuf[2*i+1] = strcard[DENOM(cards[i])];
    	cardbuf[2*i+2] = '}';
    	cardbuf[2*i+3] = 0;
    }
}
// pick an action consistent with a state node's flags
__device__ void chooseAction(BJState *s,int *amax)
{
	int tid = threadIdx.x;
    *amax = AC_STAND;
    if (s->terminal) return;
    for (;;) {
        *amax = (int) (curand_uniform(&state[tid]) * NB_ACTIONS);
        if (*amax == AC_DOUBLE && (s->flags & OK_DOUBLE) == 0) continue;
        if (*amax == AC_SPLIT && (s->flags & OK_SPLIT) == 0) continue;
        break;
    }
    //printf("choosing %s\n",choice[*amax]);
}

__device__ void nextState(BJState *state, int action, int nextC, BJState **nextP)
{
    bool splittingAces = false;
    BJState next = BJState();
	*nextP = &next;
    next.bet = (action == AC_DOUBLE ? 2 : 1) * state->bet;
    next.dealerUp = state->dealerUp;
    for (int i=0;i<16;++i) next.cards[i] = state->cards[i];
    int ncards = state->ncards;
    if (action == AC_SPLIT) --ncards;
    if (ncards == 1) {
        int denom1 = DENOMV(next.cards[0]);
        splittingAces = (denom1 == 1 && action == AC_SPLIT);
        if (!splittingAces) next.flags |= OK_DOUBLE;
        ////if (denom1 == DENOMV(nextC)) next.flags |= OK_SPLIT;
    }
    next.ncards = ncards;
    if (nextC != 0) {
        next.cards[ncards] = nextC;
        ++next.ncards;
    }
    bool issoft;
    sum(next.ncards, next.cards, &issoft, &next.sum);
    if (issoft) next.flags |= OK_SOFT;
    else if (next.sum > 21) next.terminal = true;
    if (splittingAces || action == AC_STAND || action == AC_DOUBLE) next.terminal = true;
    state->actionTaken = action;
    if (verbose) {
    	char cardbuf[50];
    	cardString(next.ncards,next.cards,cardbuf);
        printf("ac=%d(%s),nc=%d %s sum=%d,flags=%d,bet=%d\n", action, choice[action],
        	next.ncards, cardbuf, next.sum, next.flags, next.bet);
		cudaDeviceSynchronize();
    }
}

// recursively gen the game tree under this state node
__device__ void playHand(BJState *s,int *deck)
{
	if (s->terminal) {
		return;
	}
	int action;
	chooseAction(s,&action); // no sarsa learning
	//int action = selectAction(s);
	if (verbose>0) {
		char cardbuf[50];
		cardString(s->ncards,s->cards,cardbuf);
        printf("ac=%d(%s),nc=%d %s sum=%d,flags=%d,bet=%d\n", action, choice[action],
        	s->ncards, cardbuf, s->sum, s->flags, s->bet);
	}
	s->actionTaken = action;
	short nextC=0;
	if (action != AC_STAND) {
		nextCard(deck,&nextC);
		if (verbose>0) printf("Player draws a%s\n",cardName[DENOM(nextC)]);
	}
	BJState *next=NULL;
	nextState(s, action, nextC, &next);
	s->child1 = next;
	next->parent = s;
	// if (next.flags & flags_terminal && next.sum <= 21) ++unbusted;
	if (action == AC_SPLIT) {
		short t = s->cards[0];
		s->cards[0] = s->cards[1];
		nextCard(deck,&nextC);
		nextState(s, action, nextC, &next);
		s->child2 = next;
		next->parent = s;
		s->cards[0] = t;
		// if (next.flags & flags_terminal && next.sum <= 21) ++unbusted;
	}
	if (s->child1 != NULL) playHand(s->child1,deck);
	if (s->child2 != NULL) playHand(s->child2,deck);
}
