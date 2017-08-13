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
  u32 which;
  u32 in_offset;
  u32 out_offset;
  u32 net_offset;
  u32 read_len;
  u32 write_len;
  u32 base_param[2];
  u32 conv_param;
  u32 bias_param;
  u32 norm_param;
  u32 actv_param;
  u32 pool_param;
} layer;

typedef struct {
  int shape[3];
  u32 phys_addr;
  s16 *body;
} map;

typedef struct {
  int shape;
  u32 phys_addr;
  s16 *body;
} vec;

#ifdef __cplusplus
}
#endif

#endif
