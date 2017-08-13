#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>

#include "bare.h"
#include "kinpira.h"
#include "types.h"

#include <xil_mem.h>
#include <xil_cache.h>



static u32 bit(u32 value, int high, int low)
{
  return value << (31-high) >> (31-high) >> low;
}



int kinpira_init(void)
{
#if defined(zedboard)
  port       = (u32 *)                  0x43c00000U;
  mem_renkon = (u32 (*)[RENKON_WORDS])  0x43c10000U;
  mem_gobou  = (u32 (*)[GOBOU_WORDS])   0x43c80000U;
#elif defined(zcu102)
#define memcpy Xil_MemCpy
  port       = (u32 *)                  0xA0000000U;
  mem_renkon = (u32 (*)[RENKON_WORDS])  0xA0010000U;
  mem_gobou  = (u32 (*)[GOBOU_WORDS])   0xA0080000U;
#endif

  Xil_DCacheDisable();

  return 0;
}



map *define_map(int map_c, int map_w, int map_h)
{
  map *r = malloc(sizeof(map));

  r->shape[0] = map_c;
  r->shape[1] = map_w;
  r->shape[2] = map_h;

  r->body = calloc(map_c*map_w*map_h, sizeof(u16));

  return r;
}



vec *define_vec(int vec_l)
{
  vec *r = malloc(sizeof(vec));

  r->shape = vec_l;

  r->body = calloc(vec_l, sizeof(u16));

  return r;
}



void assign_map(layer *l, u32 *weight, u32 *bias)
{
  const u32 core  = RENKON_CORE;
  const u32 n_out = bit(l->base_param[0], 2*LWIDTH-1, LWIDTH);
  const u32 n_in  = bit(l->base_param[0], LWIDTH-1, 0);
  const u32 fsize = bit(l->conv_param, 2*LWIDTH-1, LWIDTH);
  const u32 unit  = n_in * fsize * fsize;

  u32 idx_w = 0;
  u32 idx_b = 0;
  u32 idx   = l->net_offset;

  u32 *null = calloc(unit+1, sizeof(u32));

  for (u32 n = 0; n < n_out/core; n++) {
    for (u32 dn = 0; dn < core; dn++) {
      memcpy(&mem_renkon[dn][idx], &weight[idx_w], sizeof(u32)*unit);
      idx_w += unit;

      memcpy(&mem_renkon[dn][idx+unit], &bias[idx_b], sizeof(u32)*1);
      idx_b += 1;
    }

    idx += unit + 1;
  }

  if (n_out % core != 0) {
    for (u32 dn = 0; dn < core; dn++) {
      if (idx_b < n_out) {
        memcpy(&mem_renkon[dn][idx], &weight[idx_w], sizeof(u32)*unit);
        idx_w += unit;

        memcpy(&mem_renkon[dn][idx+unit], &bias[idx_b], sizeof(u32)*1);
        idx_b += 1;
      }
      else {
        memcpy(&mem_renkon[dn][idx], null, sizeof(u32)*(unit+1));
      }
    }

    idx += unit + 1;
  }

  free(null);
}



void assign_vec(layer *l, u32 *weight, u32 *bias)
{
  const u32 core  = GOBOU_CORE;
  const u32 n_out = bit(l->base_param[0], 2*LWIDTH-1, LWIDTH);
  const u32 n_in  = bit(l->base_param[0], LWIDTH-1, 0);

  u32 idx_w = 0;
  u32 idx_b = 0;
  u32 idx   = l->net_offset;

  u32 *null = calloc(n_in+1, sizeof(u32));

  for (u32 n = 0; n < n_out/core; n++) {
    for (u32 dn = 0; dn < core; dn++) {
      memcpy(&mem_gobou[dn][idx], &weight[idx_w], sizeof(u32)*n_in);
      idx_w += n_in;

      memcpy(&mem_gobou[dn][idx+n_in], &bias[idx_b], sizeof(u32)*1);
      idx_b += 1;
    }

    idx += n_in + 1;
  }

  if (n_out % core != 0) {
    for (u32 dn = 0; dn < core; dn++) {
      if (idx_b < n_out) {
        memcpy(&mem_gobou[dn][idx], &weight[idx_w], sizeof(u32)*n_in);
        idx_w += n_in;

        memcpy(&mem_gobou[dn][idx+n_in], &bias[idx_b], sizeof(u32)*1);
        idx_b += 1;
      }
      else {
        memcpy(&mem_gobou[dn][idx], null, sizeof(u32)*(n_in+1));
      }
    }

    idx += n_in + 1;
  }

  free(null);
}



void undef_map(map *r)
{
  free(r->body);
  free(r);
}



void undef_vec(vec *r)
{
  free(r->body);
  free(r);
}



void exec_core(layer *l)
{
  *reg_which        = l->which;
  *reg_in_offset    = l->in_offset;
  *reg_out_offset   = l->out_offset;
  *reg_net_offset   = l->net_offset;

  *reg_pre_base     = l->in_offset;
  *reg_read_len     = l->read_len;
  *reg_write_len    = l->write_len;

  *reg_base_param0  = l->base_param[0];
  *reg_base_param1  = l->base_param[1];
  *reg_conv_param   = l->conv_param;
  *reg_bias_param   = l->bias_param;
  // *reg_norm_param = l->norm_param;
  *reg_actv_param   = l->actv_param;
  *reg_pool_param   = l->pool_param;

  *reg_pre_req = 1;
  *reg_pre_req = 0;
  do {
    // Nop
  } while (!*reg_pre_ack);


  *reg_req = 0x1;
  *reg_req = 0x0;
  do {
    // Nop
  } while (!*reg_ack);
}



int kinpira_exit(void)
{
  Xil_DCacheEnable();

  return 0;
}



void print_result(s16 *output, const u32 length)
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
    "&port[20]: %08lx &port[21]: %08lx &port[22]: %08lx &port[23]: %08lx\n"
    "&port[24]: %08lx &port[25]: %08lx &port[26]: %08lx &port[27]: %08lx\n"
    "&port[28]: %08lx &port[29]: %08lx &port[30]: %08lx &port[31]: %08lx\n"
    , port[0], port[1], port[2], port[3]
    , port[4], port[5], port[6], port[7]
    , port[8], port[9], port[10], port[11]
    , port[12], port[13], port[14], port[15]
    , port[16], port[17], port[18], port[19]
    , port[20], port[21], port[22], port[23]
    , port[24], port[25], port[26], port[27]
    , port[28], port[29], port[30], port[31]
  );
}

