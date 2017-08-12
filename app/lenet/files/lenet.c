#include <stdio.h>
#include <stdlib.h>

#include "lenet.h"
#include "types.h"
#include "layer.h"
#include "peta.h"

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



static map *image, *pmap0, *pmap1;
static layer *conv0, *conv1;

static vec *pvec1, *fvec2, *fvec3;
static layer *full2, *full3;



void LeNet_init(s16 *input, s16 **output)
{
  kinpira_init();
  puts("aa");

  image = define_map(N_IN, ISIZE, ISIZE);
  puts("bb");
  pmap0 = define_map(N_C0, PM0SIZE, PM0SIZE);
  pmap1 = define_map(N_C1, PM1SIZE, PM1SIZE);
  pvec1 = define_vec(N_C1*PM1SIZE*PM1SIZE);
  puts("cc");
  fvec2 = define_vec(N_F2);
  fvec3 = define_vec(N_F3);

  set_input(input, image);
  puts("dd");

  // TODO: remove ISIZE from convolution_2d (w/ rtl)
  conv0 = map_layer(image, pmap0, CONV0_PARAM,
    convolution_2d(FSIZE, CONV_BIAS | CONV_VALID),
    NULL,
    activation(ACTV_RELU),
    max_pooling(PSIZE)
  );
  puts("ee");

  conv1 = map_layer(pmap0, pmap1, CONV1_PARAM,
    convolution_2d(FSIZE, CONV_BIAS | CONV_VALID),
    NULL,
    activation(ACTV_RELU),
    max_pooling(PSIZE)
  );

  map2vec(pmap1, pvec1);
  puts("ff");

  full2 = vec_layer(pvec1, fvec2, FULL2_PARAM,
    fully_connected(FULL_BIAS),
    NULL,
    activation(ACTV_RELU)
  );
  puts("gg");

  full3 = vec_layer(fvec2, fvec3, FULL3_PARAM,
    fully_connected(FULL_BIAS),
    NULL,
    activation(ACTV_RELU)
  );

  set_output(fvec3, output);
  puts("hh");

  assign_map(conv0, W_conv0, b_conv0);
  puts("ii");
  assign_map(conv1, W_conv1, b_conv1);
  assign_vec(full2, W_full2, b_full2);
  puts("jj");
  assign_vec(full3, W_full3, b_full3);
}



void LeNet_eval(void)
{
  exec_core(conv0);
  exec_core(conv1);
  exec_core(full2);
  exec_core(full3);

  // assert_rep(pmap0->body, conv0_tru, N_C0*PM0SIZE*PM0SIZE);
  // assert_rep(pmap1->body, conv1_tru, N_C1*PM1SIZE*PM1SIZE);
  // assert_rep(fvec2->body, full2_tru, N_F2);
  // assert_rep(fvec3->body, full3_tru, N_F3);
}



void LeNet_exit(void)
{
  undef_map(pmap0);
  undef_map(pmap1);
  undef_vec(fvec2);
  undef_vec(fvec3);

  undef_layer(conv0);
  undef_layer(conv1);
  undef_layer(full2);
  undef_layer(full3);

  kinpira_exit();
}

