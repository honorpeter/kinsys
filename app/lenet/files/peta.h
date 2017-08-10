#ifndef _PETA_H_
#define _PETA_H_

#ifdef __cplusplus
extern "C" {
#endif

#include "types.h"

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

int kinpira_init(void);

int kinpira_exit(void);

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

void print_result(s16 *output, const u32 length);

void print_port();
#ifdef __cplusplus
}
#endif

#include "peta.c"

#endif
