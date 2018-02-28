#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>
#include <math.h>

#include "kinpira.h"

#include <assert.h>

static u64 bit(u64 value, int high, int low)
{
  return value << (BWIDTH-1-high) >> (BWIDTH-1-high) >> low;
}



#ifdef QUANT
void assign_map_quant(Layer *l, s32 *weight, s32 *bias,
                      float weight_min, float weight_max,
                      float bias_min, float bias_max)
#else
void assign_map(Layer *l, s32 *weight, s32 *bias)
#endif
{
  const int core  = RENKON_CORE;
  const int n_out = bit(l->base_param[0], 2*LWIDTH-1, LWIDTH);
  const int n_in  = bit(l->base_param[0], LWIDTH-1, 0);
  const int fsize = bit(l->conv_param[0], LWIDTH-1, 0);
  const int unit  = n_in * fsize * fsize;

  int idx_w = 0;
  int idx_b = 0;
  int idx   = l->net_offset;

  for (int n = 0; n < n_out/core; n++) {
    for (int dn = 0; dn < core; dn++) {
      for (int i = 0; i < unit; i++)
        mem_renkon[dn][idx+i] = (u64)weight[idx_w+i];
      idx_w += unit;

      mem_renkon[dn][idx+unit] = (u64)bias[idx_b];
      idx_b += 1;
    }

    idx += unit + 1;
  }

  if (n_out % core != 0) {
    for (int dn = 0; dn < core; dn++) {
      if (idx_b < n_out) {
        for (int i = 0; i < unit; i++)
          mem_renkon[dn][idx+i] = (u64)weight[idx_w+i];
        idx_w += unit;

        mem_renkon[dn][idx+unit] = (u64)bias[idx_b];
        idx_b += 1;
      }
      else {
        for (int i = 0; i < unit+1; i++)
          mem_renkon[dn][idx+i] = (u64)0;
      }
    }

    idx += unit + 1;
  }

#ifdef QUANT
  l->w_scale  = rint(((weight_max - weight_min) / 255.0) * 256.0);
  l->w_offset = rint(weight_min * 256.0);
  l->b_scale  = rint(((bias_max - bias_min) / 255.0) * 256.0);
  l->b_offset = rint(bias_min * 256.0);
#endif
}



#ifdef QUANT
void assign_vec_quant(Layer *l, s32 *weight, s32 *bias,
                      float weight_min, float weight_max,
                      float bias_min, float bias_max)
#else
void assign_vec(Layer *l, s32 *weight, s32 *bias)
#endif
{
  const int core  = GOBOU_CORE;
  const int n_out = bit(l->base_param[0], 2*LWIDTH-1, LWIDTH);
  const int n_in  = bit(l->base_param[0], LWIDTH-1, 0);

  int idx_w = 0;
  int idx_b = 0;
  int idx   = l->net_offset;

  for (int n = 0; n < n_out/core; n++) {
    for (int dn = 0; dn < core; dn++) {
      for (int i = 0; i < n_in; i++)
        mem_gobou[dn][idx+i] = (u64)weight[idx_w+i];
      idx_w += n_in;

      mem_gobou[dn][idx+n_in] = (u64)bias[idx_b];
      idx_b += 1;
    }

    idx += n_in + 1;
  }

  if (n_out % core != 0) {
    for (int dn = 0; dn < core; dn++) {
      if (idx_b < n_out) {
        for (int i = 0; i < n_in; i++)
          mem_gobou[dn][idx+i] = (u64)weight[idx_w+i];
        idx_w += n_in;

        mem_gobou[dn][idx+n_in] = (u64)bias[idx_b];
        idx_b += 1;
      }
      else {
        for (int i = 0; i < n_in+1; i++)
          mem_gobou[dn][idx+i] = (u64)0;
      }
    }

    idx += n_in + 1;
  }

#ifdef QUANT
  l->w_scale  = rint(((weight_max - weight_min) / 255.0) * 256.0);
  l->w_offset = rint(weight_min * 256.0);
  l->b_scale  = rint(((bias_max - bias_min) / 255.0) * 256.0);
  l->b_offset = rint(bias_min * 256.0);
#endif
}



void exec_core(Layer *l)
{
  *reg_which        = l->which;
  *reg_qbits        = l->qbits;
#ifdef QUANT
  *reg_w_scale      = l->w_scale;
  *reg_w_offset     = l->w_offset;
  *reg_b_scale      = l->b_scale;
  *reg_b_offset     = l->b_offset;
#endif
  *reg_in_offset    = l->in_offset;
  *reg_out_offset   = l->out_offset;
  *reg_net_offset   = l->net_offset;

  *reg_pre_base     = l->in_offset;
  *reg_read_len     = l->read_len;
  *reg_write_len    = l->write_len;

  *reg_base_param0  = l->base_param[0];
  *reg_base_param1  = l->base_param[1];
  *reg_base_param2  = l->base_param[2];
  *reg_conv_param0  = l->conv_param[0];
  *reg_conv_param1  = l->conv_param[1];
  *reg_bias_param   = l->bias_param;
  // *reg_norm_param = l->norm_param;
  *reg_actv_param   = l->actv_param;
  *reg_pool_param0  = l->pool_param[0];
  *reg_pool_param1  = l->pool_param[1];

  // print_port();

  *reg_pre_req = 0x1;
  *reg_pre_req = 0x0;
  while (!*reg_pre_ack);

  *reg_req = 0x1;
  *reg_req = 0x0;
  while (!*reg_ack);
}

void print_result(s32 *output, const int length)
{
  int number  = -1;
  int max     = INT_MIN;

  for (int i = 0; i < length; i++) {
    printf("%d: %d\n", i, output[i]);

    if (max < output[i]) {
      number = i;
      max    = output[i];
    }
  }

  printf("the answer is %d.\n", number);
}



void print_port()
{
  printf(
    "&port[0]:  %08lx &port[1]:  %08lx &port[2]:  %08lx &port[3]:  %08lx\n"
    "&port[4]:  %08lx &port[5]:  %08lx &port[6]:  %08lx &port[7]:  %08lx\n"
    "&port[8]:  %08lx &port[9]:  %08lx &port[10]: %08lx &port[11]: %08lx\n"
    "&port[12]: %08lx &port[13]: %08lx &port[14]: %08lx &port[15]: %08lx\n"
    "&port[16]: %08lx &port[17]: %08lx &port[18]: %08lx &port[19]: %08lx\n"
    "&port[20]: %08lx &port[21]: %08lx &port[22]: %08lx\n"
    "&port[60]: %08lx &port[61]: %08lx &port[62]: %08lx &port[63]: %08lx\n"
    "\n"
    , port[0], port[1], port[2], port[3]
    , port[4], port[5], port[6], port[7]
    , port[8], port[9], port[10], port[11]
    , port[12], port[13], port[14], port[15]
    , port[16], port[17], port[18], port[19]
    , port[20], port[21], port[22]
    , port[60], port[61], port[62], port[63]
  );
}

