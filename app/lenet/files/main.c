#include <stdio.h>
#include <stdlib.h>

#include "kinpira.h"
#include "types.h"
#include "util.h"
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

int main(void)
{
  s16 label[LABEL];
  s16 *input, *output;

  setbuf(stdout, NULL);
  printf("\033[2J");
#if defined(zedboard)
  puts("### lenet @ zedboard\n");
#elif defined(zcu102)
  puts("### lenet @ zcu102\n");
#endif

  LeNet_init(&input, &output);

  memmove(input, image, sizeof(s16)*N_IN*ISIZE*ISIZE);
  LeNet_eval();
  memmove(label, output, sizeof(s16)*LABEL);
  print_result(label, LABEL);
  // assert_rep(label, full3_tru, N_F3);
  // puts("assert ok");

  LeNet_exit();

  return 0;
}
