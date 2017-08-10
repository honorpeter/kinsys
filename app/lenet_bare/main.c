#include <stdio.h>
#include <stdlib.h>

#include "kinpira.h"
#include "lenet.h"
#include "bare.h"

#include "data/image.h"
#include "data/full3_tru.h"

int main(void)
{
  s16 *label;

  setbuf(stdout, NULL);
  printf("\033[2J");
#if defined(zedboard)
  puts("### rev_lenet @ zedboard\n");
#elif defined(zcu102)
  puts("### rev_lenet @ zcu102\n");
#endif

  TIME(LeNet_init(image, &label));

  TIME(LeNet_eval());

  print_result(label, LABEL);
  assert_rep(label, full3_tru, N_F3);
  puts("assert okk");

  TIME(LeNet_exit());

  return 0;
}

