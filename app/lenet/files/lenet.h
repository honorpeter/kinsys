#ifndef _LENET_H_
#define _LENET_H_

#include "kinpira.h"
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

#define INPUT_IMAGE (0)
#define CONV0_IMAGE (INPUT_IMAGE + N_IN * ISIZE * ISIZE)
#define CONV1_IMAGE (CONV0_IMAGE + N_C0 * PM0SIZE * PM0SIZE)
#define FULL2_IMAGE (CONV1_IMAGE + N_C1 * PM1SIZE * PM1SIZE)
#define FULL3_IMAGE (FULL2_IMAGE + N_F2)

// #define CEIL(a, b) ((a) % (b) == 0 ? (a) / (b) : (a) / (b) + 1)
#define CEIL(a, b) ((a) % (b) == 0 ? (a) / (b) +1 : (a) / (b) + 2)
#define CONV0_PARAM (0)
#define CONV1_PARAM (CONV0_PARAM + CEIL(N_C0, RENKON_CORE) * N_IN * (FSIZE*FSIZE+1))
#define FULL2_PARAM (0)
#define FULL3_PARAM (FULL2_PARAM + CEIL(N_F2, GOBOU_CORE) * (N_C1*PM1SIZE*PM1SIZE+1))

void LeNet_init(s16 **input, s16 **output);
void LeNet_eval(void);
void LeNet_exit(void);

#endif

