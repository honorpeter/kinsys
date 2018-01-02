#ifndef _KINPIRA_H_
#define _KINPIRA_H_

#include <stdint.h>

#define WHICH_RENKON    0
#define WHICH_GOBOU     1

#define BWIDTH          32
#define DWIDTH          16
#define LWIDTH          16
#define MEMSIZE         31
#define REGSIZE         32

#define RENKON_CORE     8
#define RENKON_NETSIZE  11
#define GOBOU_CORE      16
#define GOBOU_NETSIZE   13

#define RENKON_WORDS    2048
#define GOBOU_WORDS     8192

uint32_t *port;
uint32_t (*mem_renkon)[RENKON_WORDS];
uint32_t (*mem_gobou)[GOBOU_WORDS];

// input reg
#define reg_which       &port[0]
#define reg_req         &port[1]
#define reg_in_offset   &port[2]
#define reg_out_offset  &port[3]
#define reg_net_offset  &port[4]
#define reg_pre_req     &port[5]
#define reg_pre_base    &port[6]
#define reg_read_len    &port[7]
#define reg_write_len   &port[8]

#define reg_base_param0 &port[9]
#define reg_base_param1 &port[10]
#define reg_conv_param  &port[11]
#define reg_bias_param  &port[12]
#define reg_actv_param  &port[13]
#define reg_pool_param  &port[14]

// output reg
#define reg_r_which     &port[31]
#define reg_ack         &port[30]
#define reg_pre_ack     &port[29]
#define reg_err         &port[28]

#endif
