#ifndef _TYPES_H_
#define _TYPES_H_

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>

typedef int8_t    s8;
typedef int16_t   s16;
typedef int32_t   s32;
typedef int64_t   s64;

typedef uint8_t   u8;
typedef uint16_t  u16;
typedef uint32_t  u32;
typedef uint64_t  u64;

typedef intptr_t  INTPTR;
typedef uintptr_t UINTPTR;

typedef struct {
  u64 which;
  u64 qbits;
#ifdef __KPR_QUANT__
  u64 w_scale;
  u64 w_offset;
  u64 b_scale;
  u64 b_offset;
#endif
  u64 in_offset;
  u64 out_offset;
  u64 net_offset;
  u64 read_len;
  u64 write_len;
  u64 base_param[3];
  u64 conv_param[2];
  u64 bias_param;
  u64 norm_param;
  u64 actv_param;
  u64 pool_param[2];
} Layer;

typedef struct {
  int shape[3];
  int qbits;
  u64 phys_addr;
  s32 *body;
} Map;

typedef struct {
  int shape;
  int qbits;
  u64 phys_addr;
  s32 *body;
} Vec;

#ifdef __cplusplus
}
#endif

#endif
