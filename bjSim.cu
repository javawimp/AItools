#include "includes.h"
#include "externs.h"
#include "bjState.h"

__device__ void checkForBJs(short psum,short dsum,short *pcards,short *dcards,bool *handOver)
{
	int tid = threadIdx.x;
	*handOver = false;
	if (DENOMV(dcards[0])==1) {
		if (dsum==21) {
			if (verbose>1)printf("iter %d: Dealer has BJ!\n",tid);
			if (psum==21) {
				if (verbose>1) printf("iter %d: Player has BJ!\n",tid);
				if (verbose>1) printf("iter %d: Player pushes!\n",tid);
			} else {
				if (verbose>1) printf("iter %d: Player has %d\n",tid,psum);
				if (verbose>1) printf("iter %d: Player loses!\n",tid);
			}
			*handOver = true;
		}
	}
	if (!*handOver) {
		if (psum==21) {
			if (verbose>1) printf("iter %d: Player has BJ!\n",tid);
			if (verbose>1) printf("iter %d: Player wins!\n",tid);
			*handOver = true;
		}
	}
	cudaDeviceSynchronize();
}

__global__ void doTrial()
{
	int tid = threadIdx.x;
	const char *dlrcard[14] = { "","n A"," 2"," 3"," 4"," 5"," 6"," 7","n 8"," 9"," 10"," J"," Q"," K" };

	cudaError_t st;
	int *deck;
	bool issoft;
	short psum,dsum,pc,dc;
	short pcards[MAXCARDS],dcards[MAXCARDS];
	BJState *terminalState = NULL;

	newDeck(&deck,&st);
    nextCard(deck,&pcards[0]);
    nextCard(deck,&pcards[1]);
    pc=2;
    nextCard(deck,&dcards[0]);
    nextCard(deck,&dcards[1]);
    dc=2;
	sum(pc,pcards,&issoft,&psum);
	sum(dc,dcards,&issoft,&dsum);
	if (verbose>1) {
		printf("iter %d: d %c %c   p %c %c = %d\n",tid,
			strcard[DENOM(dcards[0])],strcard[DENOM(dcards[1])],
			strcard[DENOM(pcards[0])],strcard[DENOM(pcards[1])],psum);
		cudaDeviceSynchronize();
	}

	if (verbose>1) {
		printf("Dealer has a%s showing\n", dlrcard[DENOM(dcards[0])]);
		cudaDeviceSynchronize();
	}
	BJState initialState = BJState();
	initialState.bet = 2;
	initialState.dealerUp = DENOMV(dcards[0]);
	initialState.ncards = 2;
	initialState.cards[0] = pcards[0];
	initialState.cards[1] = pcards[1];
	initialState.sum = psum;
	initialState.flags = OK_DOUBLE | OK_SOFT;
	bool handOver;
	checkForBJs(psum,dsum,pcards,dcards,&handOver);
	if (!handOver) {
		playHand(&initialState,deck);
		//printf("ok, now eval...\n");
		evalHand(&initialState, dcards, deck);
/*
		game.bankroll += terminalState.contrib;
		if (verbose) System.out.printf("Player $%d  BR %d $/hand = %.03f\n", terminalState.contrib,game.bankroll,(float)game.bankroll/(float)iteration);
		learner.updateState(master);
*/
	}
	delete &initialState;
	cudaFree(deck);
}

int main(int argc, char *argv[]) {
	printf("welcome to cuda bj with sarsa!\n");
	int seed = 16;
	int iter = 1;
	for (int i=1;i<argc;++i) {
		if (!strcmp(argv[i],"-i")) iter = atoi(argv[++i]);
		if (!strcmp(argv[i],"-s")) seed = atoi(argv[++i]);
	}
	initbj<<<1,iter>>>(seed);
	cudaDeviceSynchronize();
	printf("ready to play!\n");
	for (int round=0;round<1;++round) {
		doTrial<<<1,iter>>>();
		cudaDeviceSynchronize();
	}
	printf("wasn't that fun?!!\n");
} 
