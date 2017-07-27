#include <stdio.h>

#include "kinpira.h"
#include "peta.h"

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

// latency analysis
#include <time.h>
#define INIT  clock_t begin, end;
#define BEGIN begin = clock();
#define END   do {                                     \
  end = clock();                                       \
  printf("%12.6f [us]\n\n",                            \
      (double)(end-begin) / CLOCKS_PER_SEC * 1000000); \
} while (0);

// #include <assert.h>
#define assert_eq(a, b) do {                                      \
  if ((a) != (b)) {                                               \
    printf("Assertion failed: %s == %s, file %s, line %d\n",      \
            #a, #b, __FILE__, __LINE__);                          \
    printf("\t%s == %x, %s == %x\n", #a, (u32)(a), #b, (u32)(b)); \
    return 1;                                                     \
  }                                                               \
} while (0)

#define assert_not(cond, fail_msg) do {                 \
  if ((cond)) {                                         \
    printf("Assertion failed: %s, file %s, line %d\n",  \
            (fail_msg), __FILE__, __LINE__);            \
    return 1;                                           \
  }                                                     \
} while (0)


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
  puts("### start lenet application:");

  assert_not(!pmap0, "pmap0 calloc failed");
  assert_not(!pmap1, "pmap1 calloc failed");
  assert_not(!fvec2, "fvec2 calloc failed");
  assert_not(!fvec3, "fvec3 calloc failed");

  define_2d(&conv0, image, pmap0, CONV0_PARAM,
            N_C0, N_IN, ISIZE, FSIZE, PSIZE);

  define_2d(&conv1, pmap0, pmap1, CONV1_PARAM,
            N_C1, N_C0, PM0SIZE, FSIZE, PSIZE);

  define_1d(&full2, pmap1, fvec2, FULL2_PARAM,
            N_F2, N_C1*PM1SIZE*PM1SIZE);

  define_1d(&full3, fvec2, fvec3, FULL3_PARAM,
            N_F3, N_F2);

  kinpira_init();

  assign_2d(&conv0, W_conv0, b_conv0);
  assign_2d(&conv1, W_conv1, b_conv1);
  assign_1d(&full2, W_full2, b_full2);
  assign_1d(&full3, W_full3, b_full3);

  puts("exec_core(&conv0)");
  BEGIN
  exec_core(&conv0);
  END

  puts("exec_core(&conv1)");
  BEGIN
  exec_core(&conv1);
  END

  puts("exec_core(&full2)");
  BEGIN
  exec_core(&full2);
  END

  puts("exec_core(&full3)");
  BEGIN
  exec_core(&full3);
  END

  kinpira_exit();

  print_result(fvec3, LABEL);

  puts("");
  for (int i = 0; i < N_C0*PM0SIZE*PM0SIZE; i++)
    assert_eq(pmap0[i], conv0_tru[i]);
  puts("conv0 assert ok");

  for (int i = 0; i < N_C1*PM1SIZE*PM1SIZE; i++)
    assert_eq(pmap1[i], conv1_tru[i]);
  puts("conv1 assert ok");

  for (int i = 0; i < N_F2; i++)
    assert_eq(fvec2[i], full2_tru[i]);
  puts("full2 assert ok");

  for (int i = 0; i < N_F3; i++)
    assert_eq(fvec3[i], full3_tru[i]);
  puts("full3 assert ok");

  return 0;
}
