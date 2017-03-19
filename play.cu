#include "includes.h"
#include "externs.h"

__device__ const char *strcard = "?A23456789TJQK";

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
	printf("welcome to cuda bj!\n");
	initbj<<<1,MAXITER+1>>>();
	cudaDeviceSynchronize();
	printf("ready to play!\n");
	for (int round=0;round<1;++round) {
		dealHand<<<1,MAXITER+1>>>();
		cudaDeviceSynchronize();
	}
	printf("was that fun?\n");
} 
