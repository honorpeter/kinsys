#ifndef _LENET_H_
#define _LENET_H_

#include "types.h"

#define N_IN    1
#define N_C0    16
#define N_C1    32
#define N_F2    128
#define N_F3    10
#define LABEL   N_F3

#define ISIZE   28
#define FSIZE   5
#define PSIZE   2

#define FM0SIZE (ISIZE-FSIZE+1)
#define PM0SIZE (FM0SIZE/PSIZE)
#define FM1SIZE (PM0SIZE-FSIZE+1)
#define PM1SIZE (FM1SIZE/PSIZE)

void LeNet_init(s16 **input, s16 **output);
void LeNet_eval(void);
void LeNet_exit(void);

#endif

