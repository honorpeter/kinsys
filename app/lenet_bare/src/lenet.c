#include <stdio.h>
#include <stdlib.h>

#include "lenet.h"
#include "kinpira.h"

#include "data/W_conv0.h"
#include "data/b_conv0.h"
#include "data/W_conv1.h"
#include "data/b_conv1.h"
#include "data/W_full2.h"
#include "data/b_full2.h"
#include "data/W_full3.h"
#include "data/b_full3.h"

#include "data/image.h"
#include "data/conv0_tru.h"
#include "data/conv1_tru.h"
#include "data/full2_tru.h"
#include "data/full3_tru.h"

static Map *image_ptr, *pmap0, *pmap1;
static Layer *conv0, *conv1;

static Vec *pvec1, *fvec2, *fvec3;
static Layer *full2, *full3;



void LeNet_init(s16 **input, s16 **output)
{
  kinpira_init();

  image_ptr = define_map(N_IN, IMG_SIZE, IMG_SIZE);
  pmap0 = define_map(N_C0, PM0_SIZE, PM0_SIZE);
  pmap1 = define_map(N_C1, PM1_SIZE, PM1_SIZE);
  pvec1 = (Vec *)malloc(sizeof(Vec));
  fvec2 = define_vec(N_F2);
  fvec3 = define_vec(N_F3);

  set_input(input, image_ptr);

  conv0 = map_layer(image_ptr, pmap0,
    convolution_2d(CONV_KERN, 1, 0, CONV_BIAS),
    NULL,
    activation(ACTV_RELU),
    pooling_2d(POOL_KERN, POOL_KERN, 0, POOL_MAX)
  );

  conv1 = map_layer(pmap0, pmap1,
    convolution_2d(CONV_KERN, 1, 0, CONV_BIAS),
    NULL,
    activation(ACTV_RELU),
    pooling_2d(POOL_KERN, POOL_KERN, 0, POOL_MAX)
  );

  map2vec(pmap1, pvec1);

  full2 = vec_layer(pvec1, fvec2,
    fully_connected(FULL_BIAS),
    NULL,
    activation(ACTV_RELU)
  );

  full3 = vec_layer(fvec2, fvec3,
    fully_connected(FULL_BIAS),
    NULL,
    activation(ACTV_RELU)
  );

  set_output(fvec3, output);

  assign_map(conv0, W_conv0, b_conv0);
  assign_map(conv1, W_conv1, b_conv1);
  assign_vec(full2, W_full2, b_full2);
  assign_vec(full3, W_full3, b_full3);
}



void LeNet_eval(void)
{
  TIME(exec_core(conv0));
  TIME(exec_core(conv1));
  TIME(exec_core(full2));
  TIME(exec_core(full3));

  assert_rep(image_ptr->body, image, N_IN*IMG_SIZE*IMG_SIZE);
  assert_rep(pmap0->body, conv0_tru, N_C0*PM0_SIZE*PM0_SIZE);
  assert_rep(pmap1->body, conv1_tru, N_C1*PM1_SIZE*PM1_SIZE);
  assert_rep(fvec2->body, full2_tru, N_F2);
  assert_rep(fvec3->body, full3_tru, N_F3);
}



void LeNet_exit(void)
{
  undef_map(image_ptr);
  undef_map(pmap0);
  undef_map(pmap1);
  free(pvec1);
  undef_vec(fvec2);
  undef_vec(fvec3);

  undef_layer(conv0);
  undef_layer(conv1);
  undef_layer(full2);
  undef_layer(full3);

  kinpira_exit();
}

