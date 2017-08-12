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
  // setbuf(stdout, NULL);
  // printf("\033[2J");
  // puts("### start lenet application:");
  //
  // const u32 image_phys_addr = phys_addr;
  // const u32 pmap0_phys_addr = phys_addr + pmap0_offset;
  // const u32 pmap1_phys_addr = phys_addr + pmap1_offset;
  // const u32 fvec2_phys_addr = phys_addr + fvec2_offset;
  // const u32 fvec3_phys_addr = phys_addr + fvec3_offset;
  //
  // define_2d(&conv0, image_phys_addr, pmap0_phys_addr, CONV0_PARAM,
  //           N_C0, N_IN, ISIZE, FSIZE, PSIZE);
  //
  // define_2d(&conv1, pmap0_phys_addr, pmap1_phys_addr, CONV1_PARAM,
  //           N_C1, N_C0, PM0SIZE, FSIZE, PSIZE);
  //
  // define_1d(&full2, pmap1_phys_addr, fvec2_phys_addr, FULL2_PARAM,
  //           N_F2, N_C1*PM1SIZE*PM1SIZE);
  //
  // define_1d(&full3, fvec2_phys_addr, fvec3_phys_addr, FULL3_PARAM,
  //           N_F3, N_F2);
  //
  // kinpira_init();
  //
  // assign_2d(&conv0, W_conv0, b_conv0);
  // assign_2d(&conv1, W_conv1, b_conv1);
  // assign_1d(&full2, W_full2, b_full2);
  // assign_1d(&full3, W_full3, b_full3);
  //
  // exec_core(&conv0);
  // exec_core(&conv1);
  // exec_core(&full2);
  // exec_core(&full3);
  //
  // print_result(fvec3, LABEL);
  //
  // kinpira_exit();
  //
  //
  // // Delete udmabuf
  // munmap(imagebuf, image_size);
  // munmap(pmap0, pmap0_size);
  // munmap(pmap1, pmap1_size);
  // munmap(fvec2, fvec2_size);
  // munmap(fvec3, fvec3_size);
  // // system("modprobe -r udmabuf");

  s16 *label;

  setbuf(stdout, NULL);
  printf("\033[2J");
#if defined(zedboard)
  puts("### lenet @ zedboard\n");
#elif defined(zcu102)
  puts("### lenet @ zcu102\n");
#endif

  TIME(LeNet_init(image, &label));

  TIME(LeNet_eval());

  print_result(label, LABEL);
  assert_rep(label, full3_tru, N_F3);
  puts("assert ok");

  TIME(LeNet_exit());

  return 0;
}
