#include "includes.h"
#include "State.h"

__shared__ int verbose;
__shared__ const char *strcard;
__shared__ int bankroll;
__shared__ const char *choice[4];
__shared__ const char *cardName[14];
__device__ curandState randstate[1024];
__device__ char dcards[1024][MAXCARDS];
__shared__ HandLedger *MasterLedger;
__shared__ double Sarsa_alpha;
__shared__ double Sarsa_gamma;
//__shared__ double table[NB_SUMS][NB_DLR][NB_FLAGS * 2][NB_ACTIONS];
__shared__ double *table;

__global__ void initbj(int seed, HandLedger *hh, double *t) {
	int tid = threadIdx.x;
	if (tid==0) {
		MasterLedger = hh;
		table = t;
		verbose = 0;
		strcard = "?A23456789TJQK";
		const char *ch[4] = {"STAND","HIT","DOUBLE","SPLIT"};
		for (int i=0;i<4;++i) choice[i] = ch[i];
		const char *cn[14] = { "","n A"," 2"," 3"," 4"," 5"," 6"," 7","n 8"," 9"," 10"," J"," Q"," K" };
		for (int i=0;i<14;++i) cardName[i] = cn[i];
		bankroll = 0;
		Sarsa_alpha = 0.1;
		Sarsa_gamma = 0.9;
	}
	curand_init(tid+seed, 0, tid, &randstate[tid]);
}
