#include "includes.h"
#include "externs.h"
#include "State.h"

// pick an action consistent with a state node's flags
__device__ void chooseAction(State *s,char *amax)
{
	int tid = threadIdx.x;
	*amax = AC_STAND;
	if (s->terminal == 1) return;
	for (;;) {
		*amax = (char) (curand_uniform(&randstate[tid]) * NB_ACTIONS);
		if (*amax == AC_DOUBLE && (s->flags & OK_DOUBLE) == 0) continue;
		if (*amax == AC_SPLIT && (s->flags & OK_SPLIT) == 0) continue;
		break;
	}
	//printf("choosing %d (%s)\n",* amax, choice[*amax]);
}

// pick an action consistent with a state node's flags using the table
__device__ void chooseSarsaAction(State *s, char *amax)
{
	*amax = AC_STAND;
	if (s->terminal == 1) return;
	chooseAction(s,amax);
        //if (Rand.randf() < epsilon) return amax;
        //*amax = 0;
        double qmax,q;
	Qget(s, *amax, &qmax);
        for (int i = 1; i < NB_ACTIONS; i++) {
            if (i == AC_DOUBLE && (s->flags & OK_DOUBLE) == 0) continue;
            if (i == AC_SPLIT && (s->flags & OK_SPLIT) == 0) continue;
	    Qget(s, i, &q);
            if (q > qmax) {
                Qget(s, i, &qmax);
                *amax = i;
            }
        }
	//printf("(Sarsa) choosing %d (%s)\n",* amax, choice[*amax]);
}

// recursively gen the game tree under this state node
__device__ void playHand(State *s)
{
	int tid = threadIdx.x;
	HandLedger *h = &MasterLedger[tid];
	if (s->terminal==1) {
		//dumpState(s,6);
		return;
	}
	char action;
	chooseSarsaAction(s,&action); // no sarsa learning
	s->action = action;
	//dumpState(s,5);
	cudaDeviceSynchronize();
	if (action == AC_STAND) {
		s->terminal = 1;
		return;
	}

	char hix = s->handIndex;
	State *next;
	if (action == AC_HIT || action == AC_DOUBLE) {
		char nextC;
		dealDeck(&nextC);
		char cix = h->ncards[hix];
		h->cards[hix][cix] = nextC;
		h->ncards[hix] += 1;
		//if (verbose>0) printf("iter %d: for card [%d]%d Player draws a%s\n", tid, hix, h->ncards[hix], cardName[DENOM(nextC)]);
		allocateState(&next);
		s->child1 = next;
		//initFromParentState(s, next);
		next->parent = s;
		next->handIndex = hix;
		next->bet = s->bet;
		next->dealer = s->dealer;
		next->ncards = h->ncards[hix];
		psumDeck(hix,&next->issoft,&next->sum);
		if (next->sum > 21) next->terminal = 1;
	}
	if (verbose>0) {
		char cardbuf[50];
		cardString(next->ncards,h->cards[hix],cardbuf);
		printf("iter %d: [next card] nc=%d %s sum=%d\n",
			tid, next->ncards, cardbuf, next->sum);
	}

	if (s->child1 != NULL) playHand(s->child1);
}
