#ifndef _LAYER_H_
#define _LAYER_H_

#ifdef __cplusplus
extern "C" {
#endif

#include "types.h"

enum conv_mode {
  CONV_BIAS   = 1U << 0,
};

enum norm_mode {
  NORM_NIL,
};

enum pool_mode {
  POOL_MAX = 1U << 0,
};

enum full_mode {
  FULL_BIAS = 1U << 0,
};

enum actv_mode {
  ACTV_RELU = 1U << 0,
};

Layer *map_layer(
  Map *in, Map *out,
  u64 *conv_param, u64 *norm_param, u64 *actv_param, u64 *pool_param
);

Layer *vec_layer(
  Vec *in, Vec *out,
  u64 *full_param, u64 *norm_param, u64 *actv_param
);

u64 *convolution_2d(int kern, int strid, int pad, int mode);
u64 *fully_connected(int mode);
u64 *normalization(int mode);
u64 *activation(int mode);
u64 *pooling_2d(int kern, int strid, int pad, int mode);

void set_input(s32 **in, Map *out);
void map2vec(Map *in, Vec *out);
void set_output(Vec *in, s32 **out);

void undef_layer(Layer *r);

#ifdef __cplusplus
}
#endif

#endif
