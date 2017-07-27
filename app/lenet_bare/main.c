#include <stdio.h>

#include "kinpira.h"
#include "bare.h"

#include "lenet.h"

#include "data/image.h"
#include "data/W_conv0.h"
#include "data/b_conv0.h"
#include "data/W_conv1.h"
#include "data/b_conv1.h"
#include "data/W_full2.h"
#include "data/b_full2.h"
#include "data/W_full3.h"
#include "data/b_full3.h"

#include "data/conv0_tru.h"
#include "data/conv1_tru.h"
#include "data/full2_tru.h"
#include "data/full3_tru.h"


int main(void)
{
  INIT

  layer conv0, conv1;
  layer full2, full3;

  // NOTE: maps could be multi dimentional array
  s16 *pmap0 = calloc(N_C0*PM0SIZE*PM0SIZE, sizeof(s16));
  s16 *pmap1 = calloc(N_C1*PM1SIZE*PM1SIZE, sizeof(s16));
  s16 *fvec2 = calloc(N_F2, sizeof(s16));
  s16 *fvec3 = calloc(N_F3, sizeof(s16));

  setbuf(stdout, NULL);
  printf("\033[2J");
#if defined(zedboard)
  puts("### lenet_bare @ zedboard\n");
#elif defined(zcu102)
  puts("### lenet_bare @ zcu102\n");
#endif

  assert_not(!pmap0, "pmap0 calloc failed");
  assert_not(!pmap1, "pmap1 calloc failed");
  assert_not(!fvec2, "fvec2 calloc failed");
  assert_not(!fvec3, "fvec3 calloc failed");

  define_2d(&conv0,
            image, pmap0, CONV0_PARAM,
            N_C0, N_IN, ISIZE, FSIZE, PSIZE);

  define_2d(&conv1,
            pmap0, pmap1, CONV1_PARAM,
            N_C1, N_C0, PM0SIZE, FSIZE, PSIZE);

  define_1d(&full2,
            pmap1, fvec2, FULL2_PARAM,
            N_F2, N_C1*PM1SIZE*PM1SIZE);

  define_1d(&full3,
            fvec2, fvec3, FULL3_PARAM,
            N_F3, N_F2);

  kinpira_init();

  TIME(assign_2d(&conv0, W_conv0, b_conv0));
  TIME(assign_2d(&conv1, W_conv1, b_conv1));
  TIME(assign_1d(&full2, W_full2, b_full2));
  TIME(assign_1d(&full3, W_full3, b_full3));

  TIME(exec_core(&conv0));
  TIME(exec_core(&conv1));
  TIME(exec_core(&full2));
  TIME(exec_core(&full3));

  kinpira_exit();

  print_result(fvec3, LABEL);

  // TODO: what's happening
  //        (existance of assert_rep has effects for value on zcu102...)
  // assert_rep(pmap0, conv0_tru, N_C0*PM0SIZE*PM0SIZE);
  assert_rep(pmap1, conv1_tru, N_C1*PM1SIZE*PM1SIZE);
  assert_rep(fvec2, full2_tru, N_F2);
  assert_rep(fvec3, full3_tru, N_F3);

  return 0;
}
