#include "includes.h"
#include "externs.h"
#include "State.h"

//[w][x][y][z] = [sx*sy*sz]*w+[sy*sz]*x+[sz]*y+z
//[NB_SUMS][NB_DLR][NB_FLAGS * 2][NB_ACTIONS];
#define TABLEINDEX(sum,dlr,flags,action) \
((NB_DLR * NB_FLAGS * 2*NB_ACTIONS)*sum +\
(NB_FLAGS * 2*NB_ACTIONS)*dlr +\
(NB_ACTIONS)*flags + action)

__device__ void Qget(State *s, char action, double *result)
    {
        if (s == NULL) {
		printf("updateQValues encountered null state!\n");
		cudaDeviceSynchronize();
		return;
        }
        int sum = s->sum;
        int dlr = s->dealer - 1;
        int flags = s->flags;
        if (verbose>9)
		printf("Qget sum=%d dlr=%d flags=%d action=%d q=%6.3f\n", sum, dlr, flags, action,
			table[TABLEINDEX(sum,dlr,flags,action)]);
        if (sum > (NB_SUMS - 1) || dlr > (NB_DLR - 1) || flags > (NB_FLAGS * 2 - 1) || action >= NB_ACTIONS) {
		//printf("Qget sum=%d dlr=%d flags=%d action=%d\n", sum, dlr, flags, action);
		*result=0.0;
		return;
        }
        //*result = table[sum][dlr][flags][action];
        *result = table[TABLEINDEX(sum,dlr,flags,action)];
    }

__device__ void Qset(State *s, char action, double value)
    {
        if (s == NULL) {
		printf("cannot Qset null state\n");
		cudaDeviceSynchronize();
		return;
        }
        int sum = s->sum;
        int dlr = s->dealer - 1;
        int flags = s->flags;
        if (verbose>9) printf("Qset sum=%d dlr=%d flags=%d action=%d q=%6.3f\n", sum, dlr, flags, action, value);
        if (sum > (NB_SUMS - 1) || dlr > (NB_DLR - 1) || flags > (NB_FLAGS * 2 - 1) || action >= NB_ACTIONS) {
		printf("out of table error in Qset: sum=%d dlr=%d flags=%d action=%d\n", sum, dlr, flags, action);
		return;
        }
        //table[sum][dlr][flags][action] = value;
        table[TABLEINDEX(sum,dlr,flags,action)] = value;
}

    // The Q(lambda) ­learning algorithm
__device__ void updateQValues(State *s, char act, float rwd, State *next_s, char next_a)
 {
        if (s == NULL) {
		printf("updateQValues encountered null state!\n");
		cudaDeviceSynchronize();
		return;
        }
        if (s->terminal == 1) {
		printf("updateQValues encountered terminal state!\n");
		cudaDeviceSynchronize();
	}
        double Q_next = 0.0;
	double oldValue = 0.0;
	Qget(next_s, next_a, &oldValue);
        if (next_s != NULL && (next_s->terminal==0)) Q_next = Sarsa_gamma * oldValue;
        Qget(s, act, &oldValue);
        double newValue = oldValue + Sarsa_alpha * (rwd + Q_next - oldValue);
        Qset(s, act, newValue);
 }

__device__ void updateSarsa(State *s)
{
        if (s->terminal==1) return;
        char a_t = s->action;
        float reward = (float) s->bank;
        if (s->child1 != NULL) {
		State *next_s = s->child1;
		char next_a = next_s->action;
		updateQValues(s, a_t, reward, next_s, next_a);
		updateSarsa(s->child1);
        }
        if (s->child2 != NULL) {
		State *next_s = s->child2;
		char next_a = next_s->action;
		updateQValues(s, a_t, reward, next_s, next_a);
		updateSarsa(s->child2);
        }
}
