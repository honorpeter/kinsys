#ifndef _UTIL_H_
#define _UTIL_H_

#include "types.h"

// #include <assert.h>
#define assert_eq(a, b) do {                                        \
  if ((a) != (b)) {                                                 \
    printf("Assertion failed: %s == %s, file %s, line %d\n",        \
            #a, #b, __FILE__, __LINE__);                            \
    printf("\t%s == %lx, %s == %lx\n", #a, (u32)(a), #b, (u32)(b)); \
    exit(1);                                                        \
  }                                                                 \
} while (0)

#define assert_rep(a, b, len) do {  \
  for (int i = 0; i < (len); i++) { \
    if (*((a)+i) != *((b)+i)) {                                 \
      printf("Assertion failed: %s == %s, file %s, line %d\n",  \
              #a, #b, __FILE__, __LINE__);                      \
      printf("\t%d: %s == %x, %s == %x\n",                      \
              i, #a, *((a)+i), #b, *((b)+i));                   \
      exit(1);                                                  \
    }                                                           \
  }                                 \
} while (0)

#define assert_not(cond, fail_msg) do {                 \
  if ((cond)) {                                         \
    printf("Assertion failed: %s, file %s, line %d\n",  \
            (fail_msg), __FILE__, __LINE__);            \
    exit(1);                                            \
  }                                                     \
} while (0)

void assign_map(Layer *l, u32 *weight, u32 *bias);
void assign_vec(Layer *l, u32 *weight, u32 *bias);

void exec_core(Layer *l);

void print_result(s16 *output, const int length);
void print_port();

#endif
