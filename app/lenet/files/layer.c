#include <stdio.h>
#include <stdlib.h>
#include <limits.h>

#include "layer.h"
#include "kinpira.h"
#include "types.h"



static void define_conv(layer *l, u32 *param);
static void define_full(layer *l, u32 *param);
static void define_norm(layer *l, u32 *param);
static void define_actv(layer *l, u32 *param);
static void define_pool(layer *l, u32 *param);



layer *map_layer(
  map *in, map *out, u32 net_offset,
  u32 *conv_param, u32 *norm_param, u32 *actv_param, u32 *pool_param
)
{
  layer *l = malloc(sizeof(layer));

  l->which      = WHICH_RENKON;
  l->in_offset  = in->phys_addr;
  l->out_offset = out->phys_addr;
  l->net_offset = net_offset;

  l->read_len   = in->shape[0] * in->shape[1] * in->shape[2];
  l->write_len  = (out->shape[0] < RENKON_CORE ? out->shape[0] : RENKON_CORE)
                * out->shape[1]
                * out->shape[2];

  l->base_param[0] = out->shape[0] << LWIDTH
                   | in->shape[0];

  l->base_param[1] = in->shape[1];

  define_conv(l, conv_param);
  define_norm(l, norm_param);
  define_actv(l, actv_param);
  define_pool(l, pool_param);

  free(conv_param);
  free(norm_param);
  free(actv_param);
  free(pool_param);

  return l;
}



layer *vec_layer(
  vec *in, vec *out, u32 net_offset,
  u32 *full_param, u32 *norm_param, u32 *actv_param
)
{
  layer *l = malloc(sizeof(layer));

  l->which      = WHICH_GOBOU;
  l->in_offset  = in->phys_addr;
  l->out_offset = out->phys_addr;
  l->net_offset = net_offset;

  l->read_len   = in->shape;
  l->write_len  = out->shape < GOBOU_CORE
                ? out->shape
                : GOBOU_CORE;

  l->base_param[0] = out->shape << LWIDTH
                   | in->shape;

  l->base_param[1] = 0;

  define_full(l, full_param);
  define_norm(l, norm_param);
  define_actv(l, actv_param);

  free(full_param);
  free(norm_param);
  free(actv_param);

  return l;
}



u32 *convolution_2d(int fil_size, enum conv_mode mode)
{
  u32 *param = calloc(2, sizeof(u32));

  param[0] |= fil_size << LWIDTH;

  if (mode & CONV_VALID)
    param[0] |= 0;
  else if (mode & CONV_SAME)
    param[0] |= (fil_size-1)/2;

  if (mode & CONV_BIAS)
    param[1] |= 1U << (BWIDTH-1);

  return param;
}



static void define_conv(layer *l, u32 *param)
{
  if (param == NULL) {
    fprintf(stderr, "map_layer must have convolution_2d attr.\n");
    exit(1);
  }
  else {
    l->conv_param = param[0];
    l->bias_param = param[1];
  }
}



u32 *fully_connected(enum full_mode mode)
{
  u32 *param = calloc(2, sizeof(u32));

  if (mode & FULL_BIAS)
    param[1] |= 1U << (BWIDTH-1);

  return param;
}



static void define_full(layer *l, u32 *param)
{
  if (param == NULL) {
    fprintf(stderr, "vec_layer must have fully_connected attr.\n");
    exit(1);
  }
  else {
    l->bias_param = param[1];
  }
}



u32 *normalization()
{
  u32 *param = calloc(1, sizeof(u32));

  return param;
}



static void define_norm(layer *l, u32 *param)
{
  if (param == NULL) {
    l->norm_param = 0;
  }
  else {
    fprintf(stderr, "normalization is not yet implemented.\n");
    exit(1);
  }
}



u32 *activation(enum actv_mode mode)
{
  u32 *param = calloc(1, sizeof(u32));

  if (mode & ACTV_RELU) {
    param[0] |= 1U << 31;
  }
  else {
    fprintf(stderr, "only relu is implemented.\n");
    exit(1);
  }

  return param;
}



static void define_actv(layer *l, u32 *param)
{
  if (param == NULL) {
    l->actv_param = 0;
  }
  else {
    l->actv_param = param[0];
  }
}



u32 *max_pooling(int pool_size)
{
  u32 *param = calloc(1, sizeof(u32));

  param[0] |= pool_size;
  param[0] |= 1U << 31;

  return param;
}



static void define_pool(layer *l, u32 *param)
{
  if (param == NULL) {
    l->pool_param = 0;
  }
  else {
    l->pool_param = param[0];
  }
}



void set_input(s16 **in, map *out)
{
#if 0
  free(out->body);

  out->body = in;
#endif

  memmove(out->body, in, out->shape[0]*out->shape[1]*out->shape[2]*sizeof(s16));
}



void map2vec(map *in, vec *out)
{
#if 0
  free(out->body);
#endif

  out->shape = in->shape[0] * in->shape[1] * in->shape[2];
  out->phys_addr = in->phys_addr;
  out->body  = in->body;
}



void set_output(vec *in, s16 **out)
{
  *out = in->body;
}



int label(vec *output)
{
  const int length = output->shape;

  int number  = -1;
  int max     = INT_MIN;

  for (int i = 0; i < length; i++) {
    if (max < output->body[i]) {
      number = i;
      max    = output->body[i];
    }
  }

  return number;
}



void undef_layer(layer *r)
{
  free(r);
}

