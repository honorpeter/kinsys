#ifndef _UTIL_H_
#define _UTIL_H_

#ifdef __cplusplus
extern "C" {
#endif

#include "types.h"

// #include <assert.h>
#define assert_eq(a, b) do {                                        \
  if ((a) != (b)) {                                                 \
    printf("Assertion failed: %s == %s, file %s, line %d\n",        \
            #a, #b, __FILE__, __LINE__);                            \
    printf("\t%s == %lx, %s == %lx\n", #a, (u64)(a), #b, (u64)(b)); \
    exit(1);                                                        \
  }                                                                 \
} while (0)

#if 0
#define assert_rep(a, b, len) do {                              \
  for (int i = 0; i < (len); i++) {                             \
    if (*((a)+i) != *((b)+i)) {                                 \
      printf("Assertion failed: %s == %s, file %s, line %d\n",  \
              #a, #b, __FILE__, __LINE__);                      \
      printf("\t%d: %s == %x, %s == %x\n",                      \
              i, #a, *((a)+i), #b, *((b)+i));                   \
      exit(1);                                                  \
    }                                                           \
  }                                                             \
} while (0)
#else
#define assert_rep(a, b, len) do {            \
  for (int i = 0; i < (len); i++) {           \
    if (*((a)+i) != *((b)+i)) {               \
      printf("\t%d:\t%s == %d, %s == %d\n",   \
              i, #a, *((a)+i), #b, *((b)+i)); \
    }                                         \
  }                                           \
} while (0)
#endif

#define assert_not(cond, fail_msg) do {                 \
  if ((cond)) {                                         \
    printf("Assertion failed: %s, file %s, line %d\n",  \
            (fail_msg), __FILE__, __LINE__);            \
    exit(1);                                            \
  }                                                     \
} while (0)

#ifdef QUANT
void assign_map_quant(Layer *l, s32 *weight, s32 *bias,
                      float weight_min, float weight_max,
                      float bias_min, float bias_max);
void assign_vec_quant(Layer *l, s32 *weight, s32 *bias,
                      float weight_min, float weight_max,
                      float bias_min, float bias_max);
#else
void assign_map(Layer *l, s32 *weight, s32 *bias);
void assign_vec(Layer *l, s32 *weight, s32 *bias);
#endif

void exec_core(Layer *l);

void print_result(s32 *output, const int length);
void print_port();

#ifdef __cplusplus
}
#endif

#endif
