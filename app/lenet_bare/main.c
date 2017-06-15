#include <stdio.h>
#include <limits.h>
#include <unistd.h>

#include <xparameters.h>
#include <xil_printf.h>

#include "kinpira.h"
#include "bare.h"

#include "lenet.h"

#include "data/input.h"
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
#include "xtime_l.h"
#define INIT  XTime begin, end;
#define BEGIN XTime_GetTime(&begin);
#define END   do {                                        \
  XTime_GetTime(&end);                                    \
  printf("%12.6f [us]\n\n",                               \
      (double)(end-begin) / COUNTS_PER_SECOND * 1000000); \
} while (0);

// #include <assert.h>
#define assert_eq(a, b) do {                                        \
  if ((a) != (b)) {                                                 \
    printf("Assertion failed: %s == %s, file %s, line %d\n",        \
            #a, #b, __FILE__, __LINE__);                            \
    printf("\t%s == %lx, %s == %lx\n", #a, (u32)(a), #b, (u32)(b)); \
    return 1;                                                       \
  }                                                                 \
} while (0)


int main(void)
{
  INIT

  layer conv0, conv1;
  layer full2, full3;
  u32 output[LABEL];

  setbuf(stdout, NULL);
  printf("\033[2J");
  puts("### start lenet_bare application:");

  define_2d(&conv0, INPUT_IMAGE, CONV0_IMAGE, CONV0_PARAM,
            N_C0, N_IN, ISIZE, FSIZE, PSIZE);
  assign_2d(&conv0, W_conv0, b_conv0);

  define_2d(&conv1, CONV0_IMAGE, CONV1_IMAGE, CONV1_PARAM,
            N_C1, N_C0, PM0SIZE, FSIZE, PSIZE);
  assign_2d(&conv1, W_conv1, b_conv1);

  define_1d(&full2, CONV1_IMAGE, FULL2_IMAGE, FULL2_PARAM,
            N_F2, N_C1*PM1SIZE*PM1SIZE);
  assign_1d(&full2, W_full2, b_full2);

  define_1d(&full3, FULL2_IMAGE, FULL3_IMAGE, FULL3_PARAM,
            N_F3, N_F2);
  assign_1d(&full3, W_full3, b_full3);

  puts("post_image(input)");
  BEGIN
  post_image(input, INPUT_IMAGE, N_IN*ISIZE*ISIZE);
  END

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

  puts("get_image(output)");
  BEGIN
  get_image(output, FULL3_IMAGE, LABEL);
  END

  //========================================================
  u32 conv0_dbg[16*12*12];
  get_image(conv0_dbg, CONV0_IMAGE, 16*12*12);
  for (int i = 0; i < 16*12*12; i++)
    assert_eq(conv0_dbg[i], conv0_tru[i]);
  puts("conv0 assert ok");

  u32 conv1_dbg[32*4*4];
  get_image(conv1_dbg, CONV1_IMAGE, 32*4*4);
  for (int i = 0; i < 32*4*4; i++)
    assert_eq(conv1_dbg[i], conv1_tru[i]);
  puts("conv1 assert ok");

  u32 full2_dbg[128];
  get_image(full2_dbg, FULL2_IMAGE, 128);
  for (int i = 0; i < 128; i++)
    assert_eq(full2_dbg[i], full2_tru[i]);
  puts("full2 assert ok");

  u32 full3_dbg[10];
  get_image(full3_dbg, FULL3_IMAGE, 10);
  for (int i = 0; i < 10; i++)
    assert_eq(full3_dbg[i], full3_tru[i]);
  puts("full3 assert ok");

  puts("");
  //========================================================

  print_result(output, LABEL);

  return 0;
}