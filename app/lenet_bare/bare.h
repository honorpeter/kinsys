#ifndef _BARE_H_
#define _BARE_H_

#ifdef __cplusplus
extern "C" {
#endif

#include <xil_types.h>

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
  s16 *in_offset, s16 *out_offset, u32 net_offset,
  u32 total_out, u32 total_in,
  u32 img_size, u32 fil_size, u32 pool_size
);
void assign_2d(layer *l, u32 *weight, u32 *bias);

void define_1d(layer *l,
  s16 *in_offset, s16 *out_offset, u32 net_offset,
  u32 total_out, u32 total_in
);
void assign_1d(layer *l, u32 *weight, u32 *bias);

void exec_core(layer *l);

void print_result(s16 *output, const u32 length);

void print_port();

#ifdef __cplusplus
}
#endif

#include "bare.c"

#endif
