#ifndef _PETA_H_
#define _PETA_H_

#ifdef __cplusplus
extern "C" {
#endif

#include "types.h"

// latency analysis
#include <time.h>
#define INIT  clock_t begin, end;
#define BEGIN begin = clock();
#define END   do {                                     \
  end = clock();                                       \
  printf("%12.6f [us]\n\n",                            \
      (double)(end-begin) / CLOCKS_PER_SEC * 1000000); \
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

Map *define_map(int map_c, int map_w, int map_h);
Vec *define_vec(int vec_l);

void undef_map(Map *r);
void undef_vec(Vec *r);

#ifdef __cplusplus
}
#endif

#endif
