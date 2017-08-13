#ifndef _BARE_H_
#define _BARE_H_

#ifdef __cplusplus
extern "C" {
#endif

#include "types.h"

// latency analysis
#include <xtime_l.h>
#define INIT  XTime begin, end;
#define BEGIN XTime_GetTime(&begin);
#define END   do {                                        \
  XTime_GetTime(&end);                                    \
  printf("  %12.6f [us]\n\n",                             \
      (double)(end-begin) / COUNTS_PER_SECOND * 1000000); \
} while (0);
#define TIME(func) do { \
  INIT                  \
  puts(#func);          \
  BEGIN                 \
  (func);               \
  END                   \
} while (0)

int kinpira_init(void);
int kinpira_exit(void);

map *define_map(int map_c, int map_w, int map_h);
vec *define_vec(int vec_l);

void undef_map(map *r);
void undef_vec(vec *r);

#ifdef __cplusplus
}
#endif

#endif
