#include <stdio.h>
#include <stdlib.h>
#include <limits.h>

#include "kinpira.h"

#define CEIL_DIV(a, b) ((a) % (b) == 0 ? (a) / (b) : (a) / (b) + 1)



static u32 renkon_offset = 0;
static u32 gobou_offset  = 0;
static int kern   = 0;
static int strid  = 0;
static int pad    = 0;
static int bias   = 0;


static void define_conv(Layer *l, u32 *param);
static void define_full(Layer *l, u32 *param);
static void define_norm(Layer *l, u32 *param);
static void define_actv(Layer *l, u32 *param);
static void define_pool(Layer *l, u32 *param);



Layer *map_layer(
  Map *in, Map *out,
  u32 *conv_param, u32 *norm_param, u32 *actv_param, u32 *pool_param
)
{
  // Layer *l = (Layer *)malloc(sizeof(Layer));
  Layer *l = (Layer *)calloc(1, sizeof(Layer));

  l->which      = WHICH_RENKON;
  l->qbits      = 8;
  l->in_offset  = in->phys_addr;
  l->out_offset = out->phys_addr;
  l->net_offset = renkon_offset;

  l->read_len   = in->shape[0] * in->shape[1] * in->shape[2];
  l->write_len  = out->shape[0] < RENKON_CORE
                ? (out->shape[0] * out->shape[1] * out->shape[2])
                : (RENKON_CORE   * out->shape[1] * out->shape[2]);

  l->base_param[0] = out->shape[0] << LWIDTH
                   | in->shape[0];

  l->base_param[1] = in->shape[1] << LWIDTH
                   | in->shape[2];

  define_conv(l, conv_param);
  define_norm(l, norm_param);
  define_actv(l, actv_param);
  define_pool(l, pool_param);

  l->base_param[2] = ((in->shape[1] + 2*pad - kern) / strid + 1) << LWIDTH
                   | ((in->shape[2] + 2*pad - kern) / strid + 1);

  renkon_offset += CEIL_DIV(out->shape[0], RENKON_CORE)
                 * (in->shape[0]*kern*kern + bias);

  // printf("renkon_offset: %d\n", renkon_offset);
  if (renkon_offset > RENKON_WORDS) {
    fprintf(stderr, "exceeds the capacity of map weight memories\n");
    exit(1);
  }

  return l;
}



Layer *vec_layer(
  Vec *in, Vec *out,
  u32 *full_param, u32 *norm_param, u32 *actv_param
)
{
  // Layer *l = (Layer *)malloc(sizeof(Layer));
  Layer *l = (Layer *)calloc(1, sizeof(Layer));

  l->which      = WHICH_GOBOU;
  l->qbits      = 8;
  l->in_offset  = in->phys_addr;
  l->out_offset = out->phys_addr;
  l->net_offset = gobou_offset;

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

  l->base_param[2] = 0;

  gobou_offset += CEIL_DIV(out->shape, GOBOU_CORE)
                * (in->shape + bias);

  // printf("gobou_offset: %d\n", gobou_offset);
  if (gobou_offset > GOBOU_WORDS) {
    fprintf(stderr, "exceeds the capacity of vec weight memories\n");
    exit(1);
  }

  return l;
}



u32 *convolution_2d(int conv_kern, int conv_strid, int conv_pad, int mode)
{
  u32 *param = (u32 *)calloc(3, sizeof(u32));

  param[0] |= conv_kern;

  param[1] |= conv_strid << LWIDTH;
  param[1] |= conv_pad;

  if (mode & CONV_BIAS)
    param[2] |= 1U << (BWIDTH-1);

  kern  = conv_kern;
  strid = conv_strid;
  pad   = conv_pad;
  bias  = (mode & CONV_BIAS) ? 1 : 0;

  return param;
}



static void define_conv(Layer *l, u32 *param)
{
  if (param == NULL) {
    fprintf(stderr, "map_layer must have convolution_2d attr.\n");
    exit(1);
  }
  else {
    l->conv_param[0] = param[0];
    l->conv_param[1] = param[1];
    l->bias_param    = param[2];
  }

  free(param);
}



u32 *fully_connected(int mode)
{
  u32 *param = (u32 *)calloc(2, sizeof(u32));

  if (mode & FULL_BIAS)
    param[1] |= 1U << (BWIDTH-1);

  kern  = 0;
  strid = 0;
  pad   = 0;
  bias  = (mode & FULL_BIAS) ? 1 : 0;

  return param;
}



static void define_full(Layer *l, u32 *param)
{
  if (param == NULL) {
    fprintf(stderr, "vec_layer must have fully_connected attr.\n");
    exit(1);
  }
  else {
    l->bias_param = param[1];
  }

  free(param);
}



u32 *normalization(int mode)
{
  u32 *param = (u32 *)calloc(1, sizeof(u32));

  if (mode & NORM_NIL)
    param[0] = 0;

  return param;
}



static void define_norm(Layer *l, u32 *param)
{
  if (param == NULL) {
    l->norm_param = 0;
  }
  else {
    fprintf(stderr, "normalization is not yet implemented.\n");
    exit(1);
  }

  free(param);
}



u32 *activation(int mode)
{
  u32 *param = (u32 *)calloc(1, sizeof(u32));

  if (mode & ACTV_RELU) {
    param[0] |= 1U << (BWIDTH-1);
  }
  else {
    fprintf(stderr, "only relu is implemented.\n");
    exit(1);
  }

  return param;
}



static void define_actv(Layer *l, u32 *param)
{
  if (param == NULL) {
    l->actv_param = 0;
  }
  else {
    l->actv_param = param[0];
  }

  free(param);
}



u32 *pooling_2d(int pool_kern, int pool_strid, int pool_pad, int mode)
{
  u32 *param = (u32 *)calloc(2, sizeof(u32));

  param[0] |= pool_kern;

  param[1] |= pool_strid << LWIDTH;
  param[1] |= pool_pad;

  if (mode & POOL_MAX) {
    param[0] |= 1U << (BWIDTH-1);
  }
  else {
    fprintf(stderr, "only max pooling is implemented.\n");
    exit(1);
  }

  return param;
}



static void define_pool(Layer *l, u32 *param)
{
  if (param == NULL) {
    l->pool_param[0] = 0;
    l->pool_param[1] = 0;
  }
  else {
    l->pool_param[0] = param[0];
    l->pool_param[1] = param[1];
  }

  free(param);
}



void set_input(s16 **in, Map *out)
{
  *in = out->body;
}



void map2vec(Map *in, Vec *out)
{
  out->shape     = in->shape[0] * in->shape[1] * in->shape[2];
  out->phys_addr = in->phys_addr;
  out->body      = in->body;
}



void set_output(Vec *in, s16 **out)
{
  *out = in->body;
}



void undef_layer(Layer *r)
{
  free(r);
}

