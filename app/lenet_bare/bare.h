#ifndef _BARE_H_
#define _BARE_H_

#ifdef __cplusplus
extern "C" {
#endif

#include "xil_types.h"

typedef struct {
  u32 which;
  u32 in_offset;
  u32 out_offset;
  u32 net_offset;
  u32 total_out;
  u32 total_in;
  u32 img_size;
  u32 fil_size;
  u32 pool_size;
} layer;

void post_image(u32 *image, const u32 offset, const u32 length);

void define_2d(layer *l,
  u32 in_offset, u32 out_offset, u32 net_offset,
  u32 total_out, u32 total_in,
  u32 img_size, u32 fil_size, u32 pool_size
);
void assign_2d(layer *l, u32 *weight, u32 *bias);

void define_1d(layer *l,
  u32 in_offset, u32 out_offset, u32 net_offset,
  u32 total_out, u32 total_in
);
void assign_1d(layer *l, u32 *weight, u32 *bias);

void exec_core(layer *l);

void get_image(u32 *image, const u32 offset, const u32 length);

void print_result(u32 *output, const u32 length);

#ifdef __cplusplus
}
#endif

#include "bare.c"

#endif
