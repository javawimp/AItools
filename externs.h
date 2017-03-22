#include "includes.h"
#include "State.h"

extern __device__ curandState randstate[1024];
extern __shared__ int verbose;
extern __shared__ const char *strcard;
extern __shared__ const char *cardAbbr;
extern __shared__ const char *choice[4];
extern __shared__ const char *cardName[14];
extern __device__ char dcards[1024][MAXCARDS];
extern __shared__ int bankroll;
extern __shared__ double Sarsa_alpha;
extern __shared__ double Sarsa_gamma;
//extern __shared__ double table[NB_SUMS][NB_DLR][NB_FLAGS * 2][NB_ACTIONS];
extern __shared__ double *table;

extern __shared__ HandLedger *MasterLedger;
// cudaMalloc'ed by host

extern __global__ void initbj(int seed, HandLedger *hh, double *table);

extern __device__ void clearState();
extern __device__ void allocateState(State **p);
extern __device__ void dumpState(State *p, int id);

extern __device__ void initializeDeck();
extern __device__ void shuffleDeck();
extern __device__ void dealDeck(char *dealt);
extern __device__ void psumDeck(int handnum, char *issoft, char *result);
extern __device__ void dsumDeck(char ncards, char *issoft, char *result);
extern __device__ void cardString(char ncards, char *cards, char *cardbuf);

extern __device__ void playHand(State *s);
extern __device__ void evalHand(State *s);

extern __device__ void Qget(State *s, char action, double *result);
extern __device__ void updateSarsa(State *s);
