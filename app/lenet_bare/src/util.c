#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>

#include "util.h"
#include "kinpira.h"
#include "types.h"

#include <assert.h>

static u32 bit(u32 value, int high, int low)
{
  return value << (BWIDTH-1-high) >> (BWIDTH-1-high) >> low;
}



void assign_map(Layer *l, u32 *weight, u32 *bias)
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
      // memmove(&mem_renkon[dn][idx], &weight[idx_w], sizeof(u32)*unit);
      for (int i = 0; i < unit; i++)
        mem_renkon[dn][idx+i] = weight[idx_w+i];
      // for (int i = 0; i < unit; i++)
      //   assert(mem_renkon[dn][idx+i] == weight[idx_w+i]);
      idx_w += unit;

      // memmove(&mem_renkon[dn][idx+unit], &bias[idx_b], sizeof(u32)*1);
      mem_renkon[dn][idx+unit] = bias[idx_b];
      // assert(mem_renkon[dn][idx+unit] == bias[idx_b]);
      idx_b += 1;
    }

    idx += unit + 1;
  }

  if (n_out % core != 0) {
    for (int dn = 0; dn < core; dn++) {
      if (idx_b < n_out) {
        // memmove(&mem_renkon[dn][idx], &weight[idx_w], sizeof(u32)*unit);
        for (int i = 0; i < unit; i++)
          mem_renkon[dn][idx+i] = weight[idx_w+i];
        // for (int i = 0; i < unit; i++)
        //   assert(mem_renkon[dn][idx+i] == weight[idx_w+i]);
        idx_w += unit;

        // memmove(&mem_renkon[dn][idx+unit], &bias[idx_b], sizeof(u32)*1);
        mem_renkon[dn][idx+unit] = bias[idx_b];
        // assert(mem_renkon[dn][idx+unit] == bias[idx_b]);
        idx_b += 1;
      }
      else {
        // memset(&mem_renkon[dn][idx], 0, sizeof(u32)*(unit+1));
        for (int i = 0; i < unit+1; i++)
          mem_renkon[dn][idx+i] = 0;
        // for (int i = 0; i < unit+1; i++)
        //   assert(mem_renkon[dn][idx+i] == 0);
      }
    }

    idx += unit + 1;
  }
}



void assign_vec(Layer *l, u32 *weight, u32 *bias)
{
  const int core  = GOBOU_CORE;
  const int n_out = bit(l->base_param[0], 2*LWIDTH-1, LWIDTH);
  const int n_in  = bit(l->base_param[0], LWIDTH-1, 0);

  int idx_w = 0;
  int idx_b = 0;
  int idx   = l->net_offset;

  for (int n = 0; n < n_out/core; n++) {
    for (int dn = 0; dn < core; dn++) {
      // memmove(&mem_gobou[dn][idx], &weight[idx_w], sizeof(u32)*n_in);
      for (int i = 0; i < n_in; i++)
        mem_gobou[dn][idx+i] = weight[idx_w+i];
      // for (int i = 0; i < n_in; i++)
      //   assert(mem_gobou[dn][idx+i] == weight[idx_w+i]);
      idx_w += n_in;

      // memmove(&mem_gobou[dn][idx+n_in], &bias[idx_b], sizeof(u32)*1);
      mem_gobou[dn][idx+n_in] = bias[idx_b];
      // assert(mem_gobou[dn][idx+n_in] == bias[idx_b]);
      idx_b += 1;
    }

    idx += n_in + 1;
  }

  if (n_out % core != 0) {
    for (int dn = 0; dn < core; dn++) {
      if (idx_b < n_out) {
        // memmove(&mem_gobou[dn][idx], &weight[idx_w], sizeof(u32)*n_in);
        for (int i = 0; i < n_in; i++)
          mem_gobou[dn][idx+i] = weight[idx_w+i];
        // for (int i = 0; i < n_in; i++)
        //   assert(mem_gobou[dn][idx+i] == weight[idx_w+i]);
        idx_w += n_in;

        // memmove(&mem_gobou[dn][idx+n_in], &bias[idx_b], sizeof(u32)*1);
        mem_gobou[dn][idx+n_in] = bias[idx_b];
        // assert(mem_gobou[dn][idx+n_in] == bias[idx_b]);
        idx_b += 1;
      }
      else {
        // memset(&mem_gobou[dn][idx], 0, sizeof(u32)*(n_in+1));
        for (int i = 0; i < n_in+1; i++)
          mem_gobou[dn][idx+i] = 0;
        // for (int i = 0; i < n_in+1; i++)
        //   assert(mem_gobou[dn][idx+i] == 0);
      }
    }

    idx += n_in + 1;
  }
}



#include <time.h>
#include <sleep.h>
void exec_core(Layer *l)
{
  *reg_which        = l->which;
  // usleep(1000);
  *reg_qbits        = l->qbits;
  // usleep(1000);
  *reg_in_offset    = l->in_offset;
  // usleep(1000);
  *reg_out_offset   = l->out_offset;
  // usleep(1000);
  *reg_net_offset   = l->net_offset;
  // usleep(1000);

  *reg_pre_base     = l->in_offset;
  // usleep(1000);
  *reg_read_len     = l->read_len;
  // usleep(1000);
  *reg_write_len    = l->write_len;
  // usleep(1000);

  *reg_base_param0  = l->base_param[0];
  // usleep(1000);
  *reg_base_param1  = l->base_param[1];
  // usleep(1000);
  *reg_base_param2  = l->base_param[2];
  // usleep(1000);
  *reg_conv_param0  = l->conv_param[0];
  // usleep(1000);
  *reg_conv_param1  = l->conv_param[1];
  // usleep(1000);
  *reg_bias_param   = l->bias_param;
  // usleep(1000);
  // *reg_norm_param = l->norm_param;
  // usleep(1000);
  *reg_actv_param   = l->actv_param;
  // usleep(1000);
  *reg_pool_param0  = l->pool_param[0];
  // usleep(1000);
  *reg_pool_param1  = l->pool_param[1];
  // usleep(1000);

  // print_port();

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

