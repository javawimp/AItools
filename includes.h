#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>
#include <cuda_runtime_api.h>
#include <curand.h>
#include <curand_kernel.h>

#define DENOM(x) (((x-1)%13)+1)
#define DENOMVAL(x) (DENOM(x)>10?10:DENOM(x))
#define MAXCARDS 16 // if two decks, else 12

#define AC_STAND  0
#define AC_HIT    1
#define AC_DOUBLE 2
#define AC_SPLIT  3
#define NB_ACTIONS 4

#define OK_DOUBLE 1
#define OK_SOFT   2
#define OK_SPLIT  4
#define NB_FLAGS  OK_SPLIT

#define MAXITER 1024
#define HitSoft17 true
#define NB_SUMS 22
#define NB_DLR 10
