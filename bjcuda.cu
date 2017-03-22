#include "includes.h"
#include "externs.h"
#include "State.h"

__device__ void checkForBJs(char psum, char dsum, int *handOver)
{
	int tid = threadIdx.x;
	*handOver = 0;
	if ((DENOMVAL(dcards[tid][0])==1 || DENOMVAL(dcards[tid][1])==1) && dsum==21) *handOver = true;
	if (psum==21) *handOver = 1;
}

__global__ void doTrial()
{
	int tid = threadIdx.x;
	HandLedger *h = &MasterLedger[tid];

	//cudaError_t st;
	//int *deck;
	char issoft, psum, dsum, dc;

	clearState();
	initializeDeck();
	shuffleDeck();
	//dealDeck(&h->cards[0][h->ncards[0]++]);
	//dealDeck(&h->cards[0][h->ncards[0]++]);
		char nextC;
		dealDeck(&nextC);
		h->cards[0][0] = nextC;
		dealDeck(&nextC);
		h->cards[0][1] = nextC;
		h->ncards[0] = 2;

	h->nhands = 1;
	dealDeck(&dcards[tid][0]);
	dealDeck(&dcards[tid][1]);
	dc=2;
	dsumDeck(dc,&issoft,&dsum);
	psumDeck(0,&issoft,&psum);
	if (verbose>9) {
		printf("iter %d: d %c %c   p %c %c = %d\n",tid,
			strcard[DENOM(dcards[tid][0])],strcard[DENOM(dcards[tid][1])],
			strcard[DENOM(h->cards[0][0])],strcard[DENOM(h->cards[0][1])],psum);
		cudaDeviceSynchronize();
	}

	if (verbose>99) {
		printf("iter %d: Dealer has a%s showing\n", tid, cardName[DENOM(dcards[tid][0])]);
		cudaDeviceSynchronize();
	}
	State *initialState;
	allocateState(&initialState);
	initialState->handIndex = 0;
	initialState->bet = 2;
	initialState->dealer = DENOMVAL(dcards[tid][0]);
	initialState->sum = psum;
	initialState->flags = OK_DOUBLE;
	initialState->issoft = issoft;
	initialState->ncards = 2;
	if (issoft) initialState->flags |= OK_SOFT; // make sure player is summed after dealer
	int handOver;
	checkForBJs(psum, dsum, &handOver);
	if (handOver==0) playHand(initialState);
	else initialState->terminal = 1;
	//for (State *p = initialState; p!=NULL; p = p->child1) printf("x%08lx . %d . %d . %d . %d . %d\n",
	//	(unsigned long)p,p->action,p->bet,p->bank,p->ncards,p->sum);
	//printf("------\n");
	evalHand(initialState);//, dcards, deck);
	if (initialState->child1) initialState->bank = initialState->child1->bank;
	//printf("%lx retrieves %d, now %d\n", initialState, initialState->child1->bank, initialState->bank);
	//dumpState(initialState, -1);
	atomicAdd(&bankroll,initialState->bank);
	if (verbose>-1) {
		printf("iter %d: Player hand $%d  total BR %d\n", tid, initialState->bank, bankroll);
	}
	updateSarsa(initialState);
}

int main(int argc, char *argv[]) {
	printf("welcome to cuda bj with sarsa!\n");
	int seed = 16;
	int iter = 1;
	int rounds = 1;
	for (int i=1;i<argc;++i) {
		if (!strcmp(argv[i],"-i")) iter = atoi(argv[++i]);
		if (!strcmp(argv[i],"-s")) seed = atoi(argv[++i]);
		if (!strcmp(argv[i],"-r")) rounds = atoi(argv[++i]);
	}
	#ifdef RESOURCE_CHECK
		size_t size;
		cudaDeviceGetLimit(&size,cudaLimitStackSize);
		printf("stack size %ld\n",size);
		cudaError_t err = cudaDeviceSetLimit(cudaLimitStackSize, 3000);
		if (err) printf("ss set error %d\n",err);
		cudaDeviceGetLimit(&size,cudaLimitPrintfFifoSize);
		printf("print fifo size %ld\n",size);
		//err = cudaDeviceSetLimit(cudaLimitPrintfFifoSize, 2000000);
		//if (err) printf("fifo set error %d\n",err);
	#endif
	printf("sizeof(HandLedger) = %ld (%04lx)\n",sizeof(HandLedger),sizeof(HandLedger));
	struct HandLedger* d;
	cudaMalloc((void**)&d, iter*sizeof(HandLedger));
	double* table;
	cudaMalloc((void**)&table, (NB_SUMS * NB_DLR * NB_FLAGS*2 * NB_ACTIONS)*sizeof(double));

	initbj<<< 1, iter >>>(seed,d,table);
	cudaDeviceSynchronize();
	printf("ready to play!\n");
	for (int round=0;round<rounds;++round) {
		doTrial<<< 1, iter >>>();
		cudaDeviceSynchronize();
	}
	cudaFree(d);
	cudaFree(table);
	printf("wasn't that fun?!!\n");
} 
