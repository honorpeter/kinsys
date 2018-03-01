#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>
#include <math.h>
#include <time.h>

#include "kinpira.h"
#ifndef __KPR_RELEASE__
#include "sim.h"
#endif

#include <assert.h>

static u64 bit(u64 value, int high, int low)
{
  return value << (BWIDTH-1-high) >> (BWIDTH-1-high) >> low;
}



#ifdef __KPR_QUANT__
void assign_map_quant(Layer *l, u8 *weight, u8 *bias,
                      int qbits,
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

#ifdef __KPR_QUANT__
  const float qoffs = 1 << qbits;
  const float w_min = weight_min * qoffs;
  const float w_max = weight_max * qoffs;
  const float b_min = bias_min * qoffs;
  const float b_max = bias_max * qoffs;
  l->w_scale  = (int)rint((w_max - w_min) / 255.0);
  l->w_offset = (int)rint(w_min);
  l->b_scale  = (int)rint((b_max - b_min) / 255.0);
  l->b_offset = (int)rint(b_min);
#endif
}



#ifdef __KPR_QUANT__
void assign_vec_quant(Layer *l, u8 *weight, u8 *bias,
                      int qbits,
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

#ifdef __KPR_QUANT__
  const float qoffs = 1 << qbits;
  l->w_scale  = rint(((weight_max - weight_min) / 255.0) * qoffs);
  l->w_offset = rint(weight_min * qoffs);
  l->b_scale  = rint(((bias_max - bias_min) / 255.0) * qoffs);
  l->b_offset = rint(bias_min * qoffs);
#endif
}



void exec_core(Layer *l)
{
  // const struct timespec req = {.tv_sec = 0, .tv_nsec = 1000};

  *reg_which        = l->which; usleep(1);
  *reg_qbits        = l->qbits; usleep(1);
#ifdef __KPR_QUANT__
  *reg_w_scale      = l->w_scale; usleep(1);
  *reg_w_offset     = l->w_offset; usleep(1);
  *reg_b_scale      = l->b_scale; usleep(1);
  *reg_b_offset     = l->b_offset; usleep(1);
#endif
  *reg_in_offset    = l->in_offset; usleep(1);
  *reg_out_offset   = l->out_offset; usleep(1);
  *reg_net_offset   = l->net_offset; usleep(1);

  *reg_pre_base     = l->in_offset; usleep(1);
  *reg_read_len     = l->read_len; usleep(1);
  *reg_write_len    = l->write_len; usleep(1);

  *reg_base_param0  = l->base_param[0]; usleep(1);
  *reg_base_param1  = l->base_param[1]; usleep(1);
  *reg_base_param2  = l->base_param[2]; usleep(1);
  *reg_conv_param0  = l->conv_param[0]; usleep(1);
  *reg_conv_param1  = l->conv_param[1]; usleep(1);
  *reg_bias_param   = l->bias_param; usleep(1);
  // *reg_norm_param = l->norm_param; usleep(1);
  *reg_actv_param   = l->actv_param; usleep(1);
  *reg_pool_param0  = l->pool_param[0]; usleep(1);
  *reg_pool_param1  = l->pool_param[1]; usleep(1);

  // print_port();

#ifdef __KPR_RELEASE__
  *reg_pre_req = 0x1; usleep(1);
  *reg_pre_req = 0x0; usleep(1);
  do { usleep(1); } while (!*reg_pre_ack);

  *reg_req = 0x1; usleep(1);
  *reg_req = 0x0; usleep(1);
  do { usleep(1); } while (!*reg_ack);
#else
  switch (*reg_which) {
    case WHICH_RENKON:
      sim_renkon();
      break;
    case WHICH_GOBOU:
      sim_gobou();
      break;
    default:
      break;
  }
#endif
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

