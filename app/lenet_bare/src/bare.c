#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>

#include "kinpira.h"

#include <xil_cache.h>



int kinpira_init(void)
{
#if defined(zedboard)
  port       = (u64 *)                  0x43c00000U;
  mem_renkon = (u64 (*)[RENKON_WORDS])  0x43c10000U;
  mem_gobou  = (u64 (*)[GOBOU_WORDS])   0x43c80000U;
#elif defined(zcu102)
  port       = (u64 *)                  0xA0000000U;
  mem_renkon = (u64 (*)[RENKON_WORDS])  0xA0020000U;
  mem_gobou  = (u64 (*)[GOBOU_WORDS])   0xA0100000U;
#endif

  Xil_DCacheDisable();
  Xil_DCacheInvalidate();

  return 0;
}



int kinpira_exit(void)
{
  Xil_DCacheEnable();

  return 0;
}



Map *define_map(int map_c, int map_w, int map_h)
{
  Map *r = (Map *)malloc(sizeof(Map));

  r->shape[0] = map_c;
  r->shape[1] = map_w;
  r->shape[2] = map_h;

  r->body = (s32 *)calloc(map_c*map_w*map_h, sizeof(s32));

  return r;
}



Vec *define_vec(int vec_l)
{
  Vec *r = (Vec *)malloc(sizeof(Vec));

  r->shape = vec_l;

  r->body = (s32 *)calloc(vec_l, sizeof(s32));

  return r;
}



void undef_map(Map *r)
{
  free(r->body);
  free(r);
}



void undef_vec(Vec *r)
{
  free(r->body);
  free(r);
}



