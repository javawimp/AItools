#include "includes.h"
#include "externs.h"

__device__ void newDeck(int **deck,cudaError_t *st) {
	int tid = threadIdx.x;
	if (verbose>2) printf("iter %d: shuffling\n",tid);
	unsigned int RAND;
	int temp[53];
	int *tdeck;
	*st = cudaMalloc((void**)&tdeck, 53 * sizeof(int));
	if (*st != cudaSuccess) {
		// compile with -rdc=true
		printf("cannot allocate deck, err = %d\n",*st);
		return;
	}
	int x = 0;
	for (int j=1; j<53; ++j) tdeck[x++] = j;
	tdeck[52] = 0;
	for (int newpos = 51; newpos >= 0; newpos--) {
		RAND = curand(&state[tid]);
		int oldpos = RAND % (newpos+1);
		temp[newpos] = tdeck[oldpos];
		for (int j = oldpos; j < newpos; j++) tdeck[j] = tdeck[j+1];
	}
	for (int i = 0; i < 52; ++i) tdeck[i] = temp[i];
/*
	// test the shuffle
	//lock(&mutex);
	printf("tid %d: ",threadIdx.x);
	for (int j = 0; j < 52; ++j) printf("%2d ",tdeck[j]);
	printf("\n");
	cudaDeviceSynchronize();
	//unlock(&mutex);
*/
	*deck = tdeck;
}

__device__ void nextCard(int *deck, short *dealt) {
	int *card = deck;
	while (*card==-1) ++card;
	*dealt = *card;
	*card = -1;
	//printf("card %2d\n",*dealt);
}

__device__ void sum(short ncards, short *hand, bool *issoft, short *result) {
	short sum = 0;
	int soft = 0;
	for (int j=0; j<ncards; ++j) {
		int denom = DENOMV(hand[j]);
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
	*result = sum;
}
