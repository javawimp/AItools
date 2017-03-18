#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>
#include <curand.h>
#include <curand_kernel.h>

#define DENOM(x) (((x-1)%13)+1)
#define DENOMV(x) (DENOM(x)>10?10:DENOM(x))
#define MAXCARDS 16 // if two decks, else 12

#define AC_STAND  0
#define AC_HIT    1
#define AC_DOUBLE 2
#define AC_SPLIT  3
#define NB_ACTIONS 3

#define OK_DOUBLE 1
#define OK_SOFT   2
#define OK_SPLIT  4
#define NB_FLAGS  OK_SPLIT

#define MAXITER 255

