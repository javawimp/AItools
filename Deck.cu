#include "includes.h"
#include "externs.h"
#include "State.h"

__device__ void cardString(char ncards, char *cards, char *cardbuf)
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

__device__ void initializeDeck() {
	int tid = threadIdx.x;
	HandLedger *h = &MasterLedger[tid];
	for (int c=0; c<52; ++c) h->deck[c] = c+1;
}

__device__ void shuffleDeck() {
	int tid = threadIdx.x;
	HandLedger *h = &MasterLedger[tid];
	unsigned int RAND;
	int temp[52];
	for (int newpos = 51; newpos >= 0; --newpos) {
		RAND = curand(&randstate[tid]);
		int oldpos = RAND % (newpos+1);
		temp[newpos] = h->deck[oldpos];
		for (int c = oldpos; c < newpos; ++c) h->deck[c] = h->deck[c+1];
	}
	for (int c = 0; c < 52; ++c) h->deck[c] = temp[c];
/*
	// test the shuffle
	printf("tid %d: ",threadIdx.x);
	for (int c = 0; c< 52; ++c) printf("%2d ",h->deck[c]);
	printf("\n");
	cudaDeviceSynchronize();
*/
}

__device__ void dealDeck(char *dealt) {
	int tid = threadIdx.x;
	HandLedger *h = &MasterLedger[tid];
	*dealt = h->deck[h->nextCard++];
}

__device__ void psumDeck(int handnum, char *issoft, char *result) {
	int tid = threadIdx.x;
	HandLedger *h = &MasterLedger[tid];
	int sum = 0;
	int soft = 0;
	for (int c=0; c<h->ncards[handnum]; ++c) {
		int denom = DENOMVAL(h->cards[handnum][c]);
		if (denom == 1) {
			denom = 11;
			++soft;
		}
		sum += denom;
	}
	while (sum > 21 && soft > 0) {
		sum -= 10;
		--soft;
	}
	*issoft = (soft>0);
	*result = (char)sum;
}

__device__ void dsumDeck(char ncards, char *issoft, char *result) {
	int tid = threadIdx.x;
	int sum = 0;
	int soft = 0;
	for (int c=0; c<ncards; ++c) {
		int denom = DENOMVAL(dcards[tid][c]);
		if (denom == 1) {
			denom = 11;
			++soft;
		}
		sum += denom;
	}
	while (sum > 21 && soft > 0) {
		sum -= 10;
		--soft;
	}
	*issoft = (soft>0);
	*result = (char)sum;
}
