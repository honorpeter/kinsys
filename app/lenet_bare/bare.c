#ifdef _BARE_H_

#include <math.h>
#include <limits.h>

#include "xil_io.h"
#include "xil_printf.h"
#include "xil_types.h"

#include "kinpira.h"
#include "lenet.h"
#include "bare.h"

#define SHIFT 256



void define_2d(layer *l,
  s16 *in_offset, s16 *out_offset, u32 net_offset,
  u32 total_out, u32 total_in,
  u32 img_size, u32 fil_size, u32 pool_size
)
{
  l->which      = RENKON;
  l->in_offset  = (u32)in_offset;
  l->out_offset = (u32)out_offset;
  l->net_offset = net_offset;
  l->total_out  = total_out;
  l->total_in   = total_in;
  l->img_size   = img_size;
  l->fil_size   = fil_size;
  l->pool_size  = pool_size;
}



void assign_2d(layer *l, u32 *weight, u32 *bias)
{
  u32 idx_w = 0;
  u32 idx_b = 0;
  u32 idx   = l->net_offset;

  const u32 core  = RENKON_CORE;
  const u32 n_out = l->total_out;
  const u32 n_in  = l->total_in;
  const u32 fsize = l->fil_size;
  const u32 unit  = n_in * fsize * fsize;

  for (u32 n = 0; n < n_out/core; n++) {
    for (u32 dn = 0; dn < core; dn++) {
      puts("ittekimasu");
      printf("&mem_renkon[dn][idx]: %p\n", &mem_renkon[dn][idx]);
      printf("&weight[idx_w]: %p\n", &weight[idx_w]);
      memmove(&mem_renkon[dn][idx], &weight[idx_w], sizeof(u32)*unit);
      puts("kitaku");
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
      else
        memset(&mem_renkon[dn][idx], 0, sizeof(u32)*(unit+1));
    }

    idx += unit + 1;
  }
}



void define_1d(layer *l,
  s16 *in_offset, s16 *out_offset, u32 net_offset,
  u32 total_out, u32 total_in
)
{
  l->which      = GOBOU;
  l->in_offset  = (u32)in_offset;
  l->out_offset = (u32)out_offset;
  l->net_offset = net_offset;
  l->total_out  = total_out;
  l->total_in   = total_in;
  l->img_size   = 0;
  l->fil_size   = 0;
  l->pool_size  = 0;
}



void assign_1d(layer *l, u32 *weight, u32 *bias)
{
  u32 idx_w = 0;
  u32 idx_b = 0;
  u32 idx   = l->net_offset;

  const u32 core  = GOBOU_CORE;
  const u32 n_out = l->total_out;
  const u32 n_in  = l->total_in;

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
      else
        memset(&mem_gobou[dn][idx], 0, sizeof(u32)*(n_in+1));
    }

    idx += n_in + 1;
  }
}



void exec_core(layer *l)
{
  *reg_which      = l->which;
  *reg_req        = 0x0;
  *reg_in_offset  = l->in_offset;
  *reg_out_offset = l->out_offset;
  *reg_net_offset = l->net_offset;
  *reg_total_out  = l->total_out;
  *reg_total_in   = l->total_in;
  *reg_img_size   = l->img_size;
  *reg_fil_size   = l->fil_size;
  *reg_pool_size  = l->pool_size;

  *reg_pre_base   = l->in_offset;
  switch (l->which) {
    case RENKON:
      *reg_read_len   = l->total_in * l->img_size * l->img_size;
      *reg_write_len  = (l->total_out < RENKON_CORE ? l->total_out : RENKON_CORE)
                      * ((l->img_size - l->fil_size + 1)/(l->pool_size))
                      * ((l->img_size - l->fil_size + 1)/(l->pool_size));
      break;
    case GOBOU:
      *reg_read_len   = l->total_in;
      *reg_write_len  = l->total_out < GOBOU_CORE ? l->total_out : GOBOU_CORE;
      break;
    default:
      *reg_read_len   = 0;
      *reg_write_len  = 0;
      break;
  }

  *reg_pre_req = 1;
  *reg_pre_req = 0;

  do {
    // Nop
  } while (!*reg_pre_ack);


  *reg_req = 0x1;
  *reg_req = 0x0;

  // Blocking till PL finishing the operation
  do {
    // Nop
  } while (!*reg_ack);
}



void print_result(s16 *output, const u32 length)
{
  int number  = -1;
  int max     = INT_MIN;

  for (int i = 0; i < length; i++) {
    printf("%d: %d\n", i, output[i]);

    if (max < output[i]) {
      max = output[i];
      number = i;
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



#endif
