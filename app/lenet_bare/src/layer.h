#ifndef _LAYER_H_
#define _LAYER_H_

#ifdef __cplusplus
extern "C" {
#endif

#include "types.h"

enum conv_mode {
  CONV_BIAS   = 1 << 0,
  CONV_VALID  = 1 << 1,
  CONV_SAME   = 1 << 2,
};

enum pool_mode {
  NIL
};

enum full_mode {
  FULL_BIAS = 1 << 0,
};

enum actv_mode {
  ACTV_RELU = 1 << 0,
};

layer *map_layer(
  map *in, map *out, u32 net_offset,
  u32 *conv_param, u32 *norm_param, u32 *actv_param, u32 *pool_param
);

layer *vec_layer(
  vec *in, vec *out, u32 net_offset,
  u32 *full_param, u32 *norm_param, u32 *actv_param
);

u32 *convolution_2d(int fil_size, enum conv_mode mode);
u32 *fully_connected(enum full_mode mode);
u32 *normalization();
u32 *activation(enum actv_mode mode);
u32 *max_pooling(int pool_size);

void set_input(s16 *in, map *out);
void map2vec(map *in, vec *out);
void set_output(vec *in, s16 **out);
int label(vec *output);

void undef_layer(layer *r);

#ifdef __cplusplus
}
#endif

#endif
