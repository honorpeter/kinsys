#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>

#include "bare.h"
#include "kinpira.h"
#include "types.h"

#include <xil_mem.h>
#include <xil_cache.h>



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



int kinpira_exit(void)
{
  Xil_DCacheEnable();

  return 0;
}



map *define_map(int map_c, int map_w, int map_h)
{
  map *r = malloc(sizeof(map));

  r->shape[0] = map_c;
  r->shape[1] = map_w;
  r->shape[2] = map_h;

  r->body = calloc(map_c*map_w*map_h, sizeof(u16));

  r->phys_addr = (u32)(UINTPTR)r->body;

  return r;
}



vec *define_vec(int vec_l)
{
  vec *r = malloc(sizeof(vec));

  r->shape = vec_l;

  r->body = calloc(vec_l, sizeof(u16));

  r->phys_addr = (u32)(UINTPTR)r->body;

  return r;
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



