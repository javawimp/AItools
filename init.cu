#include "includes.h"

__shared__ int verbose;
__shared__ const char *strcard;

__shared__ int mutex;
__device__ void lock(int* mutex) {
	// capture lock when mutex = 0.
	// we will break out of the loop after mutex gets reset
	while (atomicCAS(mutex, 0, 1) != 0);
}
__device__ void unlock(int* mutex) {
	atomicExch(mutex, 0);
}

__device__ curandState state[MAXITER];

__global__ void initbj(int seed) {
	int tid = threadIdx.x;
	if (tid==0) {
		verbose = 2;
		mutex = 0;
		strcard = "?A23456789TJQK";
	}
	curand_init(tid+seed, 0, tid, &state[tid]);
}
