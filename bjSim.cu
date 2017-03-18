#include "includes.h"
#include "externs.h"
#include "bjState.h"

__global__ void doTrial()
{
	int tid = threadIdx.x;
	const char *dlrcard[14] = { "","n A"," 2"," 3"," 4"," 5"," 6"," 7","n 8"," 9"," 10"," J"," Q"," K" };

	cudaError_t st;
	int *deck;
	bool issoft;
	short psum,dsum,pc,dc,*pcards,*dcards;
	BJState *terminalState = NULL;

	newDeck(&deck,&st);
    cudaMalloc((void**)&pcards, MAXCARDS * sizeof(int));
    cudaMalloc((void**)&dcards, MAXCARDS * sizeof(int));
    nextCard(deck,&pcards[0]);
    nextCard(deck,&pcards[1]);
    pc=2;
    nextCard(deck,&dcards[0]);
    nextCard(deck,&dcards[1]);
    dc=2;
	sum(pc,pcards,&issoft,&psum);
	sum(dc,dcards,&issoft,&dsum);
	if (verbose) {
		printf("iter %d: d %c %c p %c %c = %d\n",tid,
			strcard[DENOMV(dcards[0])],strcard[DENOMV(dcards[1])],
			strcard[DENOMV(pcards[0])],strcard[DENOMV(pcards[1])],psum);
		cudaDeviceSynchronize();
	}

	if (verbose) {
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
	
	playHand(&initialState,deck);
/*
	master = learner.nextState(initialState, BJSarsa.HIT, d.hand[1][1]);
	initialState.child1 = master;
	learner.playHand(master);
	boolean noDlrBJ = game.finish(iteration);
	if (noDlrBJ) {
		learner.evalHands(master, game.dsum);
		game.bankroll += terminalState.contrib;
		if (verbose) System.out.printf("Player $%d  BR %d $/hand = %.03f\n", terminalState.contrib,game.bankroll,(float)game.bankroll/(float)iteration);
		learner.updateState(master);
	}
*/
	delete &initialState;
	cudaFree(pcards);
	cudaFree(dcards);
	cudaFree(deck);
}

int main(int argc, char *argv[]) {
	printf("welcome to cuda bj with sarsa!\n");
	int seed = 16;
	if (argc>1) seed = atoi(argv[1]);
	initbj<<<1,1>>>(seed);
	cudaDeviceSynchronize();
	printf("ready to play!\n");
	for (int round=0;round<1;++round) {
		doTrial<<<1,1>>>();
		cudaDeviceSynchronize();
	}
	printf("wasn't that fun?!!\n");
} 
