#include "includes.h"
#include "bjState.h"

extern __device__ curandState state[MAXITER];

extern __global__ void initbj(int seed);

extern __device__ void newDeck(int **deck,cudaError_t *st);
extern __device__ void nextCard(int *deck, short *dealt);
extern __device__ void sum(short ncards, short *hand, bool *issoft, short *result);

extern __device__ void playHand(BJState *s,int *deck);

extern __shared__ int verbose;
extern __shared__ const char *strcard;
