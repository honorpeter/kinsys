#ifndef _LENET_H_
#define _LENET_H_

#include "types.h"

#define N_IN    1
#define N_C0    16
#define N_C1    32
#define N_F2    128
#define N_F3    10
#define LABEL   N_F3

#define IMG_SIZE   28
#define CONV_KERN   5
#define POOL_KERN   2

#define FM0SIZE (IMG_SIZE-CONV_KERN+1)
#define PM0SIZE (FM0SIZE/POOL_KERN)
#define FM1SIZE (PM0SIZE-CONV_KERN+1)
#define PM1SIZE (FM1SIZE/POOL_KERN)

void LeNet_init(s16 **input, s16 **output);
void LeNet_eval(void);
void LeNet_exit(void);

#endif

