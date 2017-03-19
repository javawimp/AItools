#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>
#include <curand.h>
#include <curand_kernel.h>

#define DENOM(x) (((x-1)%13)+1)#define DENOMV(x) (DENOM(x)>10?10:DENOM(x))
#define MAXCARDS 16 // if two decks, else 12

__shared__ int verbose;

__device__ const char *strcard = "?A23456789TJQK";
__shared__ int mutex;
__device__ void lock(int* mutex) {
  // capture lock when mutex = 0.
  // we will break out of the loop after mutex gets reset
  while (atomicCAS(mutex, 0, 1) != 0);
}
__device__ void unlock(int* mutex) {
  atomicExch(mutex, 0);
}

__device__ curandState state[256];

__global__ void initbj() {
	int tid = threadIdx.x;
	if (tid==0) {
		verbose = 1;
		mutex = 0;
	}
	curand_init(tid, 0, tid, &state[tid]);
}

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

__device__ void nextCard(int *deck, int *dealt) {
	int *card = deck;
	while (*card==-1) ++card;
	*dealt = *card;
	*card = -1;
	//printf("card %2d\n",*dealt);
}

__device__ void sum(int ncards, int *hand, int *result) {
	int sum = 0;
	int issoft = 0;
	for (int j=0; j<ncards; ++j) {
		int denom = DENOMV(hand[j]);
		if (denom == 1) {
			denom = 11;
			++issoft;
		}
		sum += denom;
	}
	while (sum > 21 && issoft > 0) {
		sum -= 10;
		--issoft;
	}
	*result = sum;
}

/*{
deal 2 cards to player
deal 2 cards to dealer
is dealer upcard ace?
	yes: dealer bj?
		yes: player bj?
			yes: push; return
			no: player loses; return
		no: playout()
	no: player bj?
		yes: player wins; return
		no: playout()

playout()
	action
	stand:
		dealer()
	if (psum<=21) hit:
		playout()
	if (ncards=2)
	double:
		draw()
		dealer()

dealer()
	if (psum>21) player loses; return
	if (player bj) player wins; return
	if (dsum>17) compare; return
	if (dsum>21 && soft) ddraw(); dealer()
	ddraw(); dealer()
}*/

__device__ void playout(int pc,int dc,int *pcards,int *dcards,int *deck,bool *done) {
	int tid = threadIdx.x;
	char buf[100];
	for (int i=0;i<pc;++i) { buf[i*2] = ' '; buf[i*2+1] = strcard[DENOMV(pcards[i])]; }
	buf[2*pc]=0;
	if (verbose>1) printf("tid %d: d shows %c p has%s\n",tid,strcard[DENOMV(dcards[0])],buf);
	int RAND = curand(&state[tid]);
	int psum;
	sum(pc,pcards,&psum);
	int action = RAND & 3;
	if (psum > 21) action = 0;
	if (pc > 2 && action == 2) action = 3;
	if (verbose>1) printf("iter %d: Player has %d action = %d\n",tid,psum,action);
	if (action == 0) {
		//printf("iter %d: done\n",tid);
		*done = true;
		return;
	}
	if (action == 2) {
		//printf("iter %d: doubling\n",tid);
		++pc;
		nextCard(deck,&pcards[pc-1]);
		if (verbose>1) printf("iter %d: Player doubles down and draws a %c\n",tid,strcard[DENOMV(pcards[pc-1])]);
		*done = true;
		return;
	}
	++pc;
	nextCard(deck,&pcards[pc-1]);
	playout(pc,dc,pcards,dcards,deck,done);
}

#define MAXITER 255

//__global__ void dealHand(int pc,int dc,int *pcards,int *dcards,int *deck) {
__global__ void dealHand() {
	int tid = threadIdx.x;
	if (tid>MAXITER) return;
	if (verbose>2) printf("iteration %d\n",tid);
	int *mydeck,psum,dsum,pc,dc,*pcards,*dcards;
	bool done = false;

	cudaError_t st;
	newDeck(&mydeck,&st);
	if (st) return;
        cudaMalloc((void**)&pcards, MAXCARDS * sizeof(int));
        cudaMalloc((void**)&dcards, MAXCARDS * sizeof(int));
        nextCard(mydeck,&pcards[0]);
        nextCard(mydeck,&pcards[1]);
        pc=2;
        nextCard(mydeck,&dcards[0]);
        nextCard(mydeck,&dcards[1]);
        dc=2;
	if (verbose>1) printf("iter %d: p %c %c d %c %c\n",tid,
		strcard[DENOMV(pcards[0])],strcard[DENOMV(pcards[1])],
		strcard[DENOMV(dcards[0])],strcard[DENOMV(dcards[1])]);
	cudaDeviceSynchronize();
	sum(pc,pcards,&psum);
	sum(dc,dcards,&dsum);
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
			done = true;
		}
	}
	if (!done) {
		if (psum==21) {
			if (verbose>1) printf("iter %d: Player has BJ!\n",tid);
			if (verbose>1) printf("iter %d: Player wins!\n",tid);
			done = true;
		}
	}

	if (!done) {
		if (verbose>2) printf("tid %d: more to come. p = %d d = %d\n",tid,psum,dsum);
		playout(pc,dc,pcards,dcards,mydeck,&done);
	}
	cudaFree(pcards);
	cudaFree(dcards);
	cudaFree(mydeck);
}

int main(int argc, char *argv[]) {
	//cudaDeviceReset();
	printf("welcome to cuda bj!\n");
	initbj<<<1,MAXITER+1>>>();
	cudaDeviceSynchronize();
	printf("ready to play!\n");
	for (int round=0;round<20;++round) {
		dealHand<<<1,MAXITER+1>>>();
		cudaDeviceSynchronize();
	}
	//dealHand<<<1,MAXITER+1>>>();
	//cudaDeviceSynchronize();
	printf("was that fun?\n");
} 
