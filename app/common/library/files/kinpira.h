#ifndef _KINPIRA_H_
#define _KINPIRA_H_

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>

#define WHICH_RENKON    0
#define WHICH_GOBOU     1

#define BWIDTH          32
#define DWIDTH          16
#define LWIDTH          16
#define MEMSIZE         31
#define REGSIZE         64

#ifdef __KPR_QUANT__
#define RENKON_CORE     8
#define RENKON_NETSIZE  18
#define RENKON_WORDS    262144
#define GOBOU_CORE      2
#define GOBOU_NETSIZE   1
#define GOBOU_WORDS     2
#else
#define RENKON_CORE     8
#define RENKON_NETSIZE  11
#define RENKON_WORDS    2048
#define GOBOU_CORE      16
#define GOBOU_NETSIZE   13
#define GOBOU_WORDS     8192
#endif

extern uint32_t *port;
extern uint32_t (*mem_renkon)[RENKON_WORDS];
extern uint32_t (*mem_gobou)[GOBOU_WORDS];
extern int16_t *mem_image;

// input reg
#define reg_which       &port[0]
#define reg_req         &port[1]
#define reg_qbits       &port[2]
#ifdef __KPR_QUANT__
#define reg_w_scale     &port[3]
#define reg_w_offset    &port[4]
#define reg_b_scale     &port[5]
#define reg_b_offset    &port[6]
#endif
#define reg_in_offset   &port[7]
#define reg_out_offset  &port[8]
#define reg_net_offset  &port[9]
#define reg_pre_req     &port[10]
#define reg_pre_base    &port[11]
#define reg_read_len    &port[12]
#define reg_write_len   &port[13]

#define reg_base_param0 &port[14]
#define reg_base_param1 &port[15]
#define reg_base_param2 &port[16]
#define reg_conv_param0 &port[17]
#define reg_conv_param1 &port[18]
#define reg_bias_param  &port[19]
#define reg_actv_param  &port[20]
#define reg_pool_param0 &port[21]
#define reg_pool_param1 &port[22]

// output reg
#define reg_r_which     &port[63]
#define reg_ack         &port[62]
#define reg_pre_ack     &port[61]
#define reg_err         &port[60]

#include "types.h"
#include "peta.h"
#include "util.h"
#include "layer.h"

#ifdef __cplusplus
}
#endif

#endif
