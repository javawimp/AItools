#include "includes.h"
#include "externs.h"

__device__ void clearState()
{
	int tid = threadIdx.x;
	union un u;
	u.hlp = &MasterLedger[tid];
	//printf("clear ledger [%d] at %lx\n",tid,u.hlp);
	for (int i=0;i<HL_ISIZE;++i) u.g[i] = 0;
}

__device__ void allocateState(State **p)
{
	int tid = threadIdx.x;
	HandLedger *h = &MasterLedger[tid];
	struct State *b = &h->bjstate[h->nextBlock++];
	//printf("[%d] allocated block at %lx\n",tid,b);
	*p = b;
}

__device__ void dumpState(State *p, int id)
{
	int tid = threadIdx.x;
	HandLedger *h = &MasterLedger[tid];
	printf("[%d][%lx] iter %d: act %d(%s) bet %d bank %d du %d nh %d nc %d sum %d fl %d t %d pr %lx ch1 %lx ch2 %lx\n",
		id,p,tid,
		p->action,choice[p->action],p->bet,p->bank,p->dealer,h->nhands,p->ncards,p->sum,p->flags,p->terminal,
		(long)p->parent,(long)p->child1,(long)p->child2);
	for (int nh=0; nh<h->nhands; ++nh) {
		for (int nc=0; nc<h->ncards[nh]; ++nc)
			printf("[%lx,%d,%d]",p,nc,DENOM(h->cards[nh][nc]));
		printf("\n");
	}
	cudaDeviceSynchronize();
}
