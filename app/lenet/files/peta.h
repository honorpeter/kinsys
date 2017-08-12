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

void set_input(s16 **in, map *out);
vec *vec_of_map(map *m);
void set_output(vec *in, s16 **out);

void undef_map(map *r);
void undef_vec(vec *r);

#ifdef __cplusplus
}
#endif

#endif
