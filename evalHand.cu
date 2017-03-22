#include "includes.h"
#include "externs.h"
#include "State.h"

/*
	this routine descends to the leaf nodes, evaluates the final
	profit/loss of each node representing one hand after any
	splits,and passes the "reward" back up the tree as "contrib".
	"contrib" will be modified by Sarsa evaluations.
*/

__device__
void evalHand(State *s) //, int *dcards, int *deck)
{
	int tid = threadIdx.x;
	HandLedger *h = &MasterLedger[tid];
	//dumpState(s,99);
//#ifdef NEVER
#if 1
	char dsum, issoft;
	//csum(s->ncards,s->cards,&s->issoft,&s->sum);
	if (s->sum>21) s->terminal = 1;
	if (s->terminal == 1) {
		if (s->sum < 22)
			if (verbose>0) {
			printf("iter %d: eH checking dealer. psum = %d\n", tid, s->sum);
			cudaDeviceSynchronize();
			}
		dsumDeck(2,&issoft,&dsum);
		int handOver = false;
		if (DENOMVAL(dcards[tid][0])==1) {
			if (dsum==21) {
				if (verbose>1) printf("iter %d: Dealer has BJ!\n", tid);
				if (s->sum==21 && s->ncards==2) {
					if (verbose>1) printf("iter %d: Player has BJ and pushes!\n", tid);
					s->bank = 0;
				} else {
					if (verbose>1) printf("iter %d: Player has %d and loses!\n", tid, s->sum);
					s->bank = -(s->bet);
				}
				if (verbose>1) cudaDeviceSynchronize();
				handOver = true;
			}
		}
		if (!handOver) {
			if (s->sum==21 && s->ncards==2) {
				if (verbose>1) {
					printf("iter %d: Player has BJ and wins!\n",tid);
					cudaDeviceSynchronize();
				}
				s->bank = s->bet * 3 / 2;
				handOver = true;
			}
		}
		if (!handOver) {
			if (s->sum<22) {
				int ncards = 2;
				do {
					if (dsum < 17 || (dsum == 17 && issoft && HitSoft17)) {
						char nextC;
						dealDeck(&nextC);
						dcards[tid][ncards++] = nextC;
						dsumDeck(ncards,&issoft,&dsum);
						if (verbose>1) printf("iter %d: Dealer draws a %c.  Total is %d\n", tid, strcard[DENOM(nextC)],dsum);
					}
				}
				while (dsum < 17);
			}
			char *eval;
			if (s->sum > 21) {
				eval = (char*)"busts";
				s->bank = -(s->bet);
			} else if (s->sum < dsum && dsum < 22) {
				eval = (char*)"loses";
				s->bank = -(s->bet);
			} else if (s->sum == dsum) {
				eval = (char*)"pushes";
				s->bank = 0;
			} else {
				eval = (char*)"wins";
				s->bank = s->bet;
			}
			if (verbose>1) {
				char cardbuf[50];
				cardString(s->ncards,h->cards[s->handIndex],cardbuf);
				printf("iter %d: Hand %s = %d and %s $%d\n", tid, cardbuf, s->sum, eval, s->bank);
				cudaDeviceSynchronize();
			}
		}
		/*
		if (s->parent != NULL) {
			printf("%lx (trm) passing %d up to %lx\n", s, s->bank, s->parent);
			cudaDeviceSynchronize();
			s->parent->bank += s->bank;
		}
		*/
		//dumpState(s,0);
		return;
	}
#endif
	if (s->child1 != NULL) {
		State *ch = s->child1;
		//printf("follow %lx to ch1 %lx\n", s, ch);
		//dumpState(ch,1);
		evalHand(ch);//, dcards, deck);
		//printf("back from ch1 %lx to %lx\n", ch, s);
		//dumpState(ch,1);
		//dumpState(s,2);
		//if (s->child1->terminal)
		s->bank += ch->bank;
		//printf("%lx retrieves %d, now %d\n", s, ch->bank, s->bank);
	}
	/*
	if (s->parent != NULL) {
		//printf("%lx passing %d up to %lx\n", s, s->contrib, s->parent);
		s->parent->contrib += s->contrib;
	}
	cudaDeviceSynchronize();
	if (s->child2 != NULL) { // hand was split into two
		//s->child2->dump(2, tid);
		evalHand(s->child2, dcards, deck);
		//if (s->child2->terminal) s->contrib += s->child2->contrib;
	}
	*/
}
