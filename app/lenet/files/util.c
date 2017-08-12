#include <stdio.h>
#include <stdlib.h>
#include <limits.h>

#include "util.h"
#include "kinpira.h"
#include "types.h"

static u32 bit(u32 value, int high, int low)
{
  return value << (31-high) >> (31-high) >> low;
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

  for (u32 n = 0; n < n_out/core; n++) {
    for (u32 dn = 0; dn < core; dn++) {
      memmove(&mem_renkon[dn][idx], &weight[idx_w], sizeof(u32)*unit);
      idx_w += unit;

      memmove(&mem_renkon[dn][idx+unit], &bias[idx_b], sizeof(u32)*1);
      idx_b += 1;
    }

    idx += unit + 1;
  }

  if (n_out % core != 0) {
    for (u32 dn = 0; dn < core; dn++) {
      if (idx_b < n_out) {
        memmove(&mem_renkon[dn][idx], &weight[idx_w], sizeof(u32)*unit);
        idx_w += unit;

        memmove(&mem_renkon[dn][idx+unit], &bias[idx_b], sizeof(u32)*1);
        idx_b += 1;
      }
      else {
        memset(&mem_renkon[dn][idx], 0, sizeof(u32)*(unit+1));
      }
    }

    idx += unit + 1;
  }
}



void assign_vec(layer *l, u32 *weight, u32 *bias)
{
  const u32 core  = GOBOU_CORE;
  const u32 n_out = bit(l->base_param[0], 2*LWIDTH-1, LWIDTH);
  const u32 n_in  = bit(l->base_param[0], LWIDTH-1, 0);

  u32 idx_w = 0;
  u32 idx_b = 0;
  u32 idx   = l->net_offset;

  for (u32 n = 0; n < n_out/core; n++) {
    for (u32 dn = 0; dn < core; dn++) {
      memmove(&mem_gobou[dn][idx], &weight[idx_w], sizeof(u32)*n_in);
      idx_w += n_in;

      memmove(&mem_gobou[dn][idx+n_in], &bias[idx_b], sizeof(u32)*1);
      idx_b += 1;
    }

    idx += n_in + 1;
  }

  if (n_out % core != 0) {
    for (u32 dn = 0; dn < core; dn++) {
      if (idx_b < n_out) {
        memmove(&mem_gobou[dn][idx], &weight[idx_w], sizeof(u32)*n_in);
        idx_w += n_in;

        memmove(&mem_gobou[dn][idx+n_in], &bias[idx_b], sizeof(u32)*1);
        idx_b += 1;
      }
      else {
        memset(&mem_gobou[dn][idx], 0, sizeof(u32)*(n_in+1));
      }
    }

    idx += n_in + 1;
  }
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

void print_result(s16 *output, const int length)
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
    "&port[0]:  %08x &port[1]:  %08x &port[2]:  %08x &port[3]:  %08x\n"
    "&port[4]:  %08x &port[5]:  %08x &port[6]:  %08x &port[7]:  %08x\n"
    "&port[8]:  %08x &port[9]:  %08x &port[10]: %08x &port[11]: %08x\n"
    "&port[12]: %08x &port[13]: %08x &port[14]: %08x &port[15]: %08x\n"
    "&port[16]: %08x &port[17]: %08x &port[18]: %08x &port[19]: %08x\n"
    "&port[20]: %08x &port[21]: %08x &port[22]: %08x &port[23]: %08x\n"
    "&port[24]: %08x &port[25]: %08x &port[26]: %08x &port[27]: %08x\n"
    "&port[28]: %08x &port[29]: %08x &port[30]: %08x &port[31]: %08x\n"
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
