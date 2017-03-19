#include "includes.h"
#include "externs.h"
#include "bjState.h"

__device__ void evalHand(BJState *s, short *dcards, int *deck)
{
	//printf("adr %08lx\n",(unsigned long)s);
	//cudaDeviceSynchronize();
	//printf("into eH nc %d term %d adr %08lx\n",s->ncards,s->terminal,(unsigned long)s);
	//cudaDeviceSynchronize();
	if (s->child1 != NULL) {
        evalHand(s->child1, dcards, deck);
        if (s->child1->terminal) s->contrib = s->child1->contrib;
    }
    if (s->child2 != NULL) {
        evalHand(s->child2, dcards, deck);
        if (s->child1->terminal) s->contrib += s->child2->contrib;
    }
    if (s->terminal==0) {
    	//printf("eH bye\n");
    	//cudaDeviceSynchronize();
    	return;
	}
	printf("eH checking dealer. psum = %d\n",s->sum);
	cudaDeviceSynchronize();
    short dsum;
    bool issoft;
    if (s->sum<22) {
    	sum(2,dcards,&issoft,&dsum);
    	short ncards = 2;
        do {
            if (dsum < 17 || (dsum == 17 && issoft && HitSoft17)) {
            	short nextC;
            	nextCard(deck,&nextC);
				dcards[ncards++] = nextC;
		       	sum(ncards,dcards,&issoft,&dsum);
				if (verbose>1) printf("Dealer draws a %c.  Total is %d\n",strcard[DENOM(nextC)],dsum);
            }
        }
        while (dsum < 17);
    }
    char *eval;
    if (s->sum > 21) {
        eval = (char*)"busts";
        s->contrib = -s->bet;
    } else if (s->sum < dsum && dsum < 22) {
        eval = (char*)"loses";
        s->contrib = -s->bet;
    } else if (s->sum == dsum) {
        eval = (char*)"pushes";
        s->contrib = 0;
    } else {
        eval = (char*)"wins";
        if (s->sum == 21 && (s->ncards) == 2) {
            eval = (char*)"wins by BJ";
            s->contrib = s->bet * 3 / 2;
        } else s->contrib = s->bet;
    }
    if (verbose>1) {
    	char cardbuf[50];
    	cardString(s->ncards,s->cards,cardbuf);
        printf("Hand %s = %d and %s $%d\n", cardbuf, s->sum, eval, s->contrib);
    }
    //terminalState = s;
}
