#ifdef _BARE_H_

#include <math.h>
#include <limits.h>

#include "xil_io.h"
#include "xil_printf.h"
#include "xil_types.h"

#include "kinpira.h"
#include "bare.h"

#define SHIFT 256



void post_image(u32 *image, const u32 offset, const u32 length)
{
  *reg_which = NINJIN;
  // NOTE: width of each entry have to be adjusted with care.
  memmove(&mem_image[offset], image, sizeof(u32)*length);
}



void define_2d(layer *l,
  u32 in_offset, u32 out_offset, u32 net_offset,
  u32 total_out, u32 total_in,
  u32 img_size, u32 fil_size, u32 pool_size
)
{
  l->which      = RENKON;
  l->in_offset  = in_offset;
  l->out_offset = out_offset;
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
      else
        memset(&mem_renkon[dn][idx], 0, sizeof(u32)*(unit+1));
    }

    idx += unit + 1;
  }
}



void define_1d(layer *l,
  u32 in_offset, u32 out_offset, u32 net_offset,
  u32 total_out, u32 total_in
)
{
  l->which      = GOBOU;
  l->in_offset  = in_offset;
  l->out_offset = out_offset;
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

  *reg_req = 0x1;
  *reg_req = 0x0;

  // Blocking till PL finishing the operation
  do {
    // Nop
  } while (!*reg_ack);
}



void get_image(u32 *image, const u32 offset, const u32 length)
{
  *reg_which = NINJIN;
  memmove(image, &mem_image[offset], sizeof(u32)*length);
}



void print_result(u32 *output, const u32 length)
{
  int number  = -1;
  int max     = INT_MIN;

  for (int i = 0; i < length; i++) {
    printf("%d: %d\n", i, (s16)output[i]);

    if (max < (s16)output[i]) {
      max = (s16)output[i];
      number = i;
    }
  }

  printf("the answer is %d.\n", number);
}



#endif
