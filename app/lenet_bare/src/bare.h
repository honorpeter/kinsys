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

// #include <assert.h>
#define assert_eq(a, b) do {                                        \
  if ((a) != (b)) {                                                 \
    printf("Assertion failed: %s == %s, file %s, line %d\n",        \
            #a, #b, __FILE__, __LINE__);                            \
    printf("\t%s == %lx, %s == %lx\n", #a, (u32)(a), #b, (u32)(b)); \
    return 1;                                                       \
  }                                                                 \
} while (0)

#define assert_rep(a, b, len) do {  \
  for (int i = 0; i < (len); i++) { \
    assert_eq(*((a)+i), *((b)+i));  \
  }                                 \
} while (0)

#define assert_not(cond, fail_msg) do {                 \
  if ((cond)) {                                         \
    printf("Assertion failed: %s, file %s, line %d\n",  \
            (fail_msg), __FILE__, __LINE__);            \
    return 1;                                           \
  }                                                     \
} while (0)

int kinpira_init(void);

int kinpira_exit(void);

map *define_map(int map_c, int map_w, int map_h);
vec *define_vec(int vec_l);

void assign_map(layer *l, u32 *weight, u32 *bias);
void assign_vec(layer *l, u32 *weight, u32 *bias);

void undef_map(map *r);
void undef_vec(vec *r);

void exec_core(layer *l);

void print_result(s16 *output, const u32 length);

void print_port();

#ifdef __cplusplus
}
#endif

#endif
