#ifndef _KINPIRA_H_
#define _KINPIRA_H_

#include "xil_types.h"

#define RENKON  0
#define GOBOU   1
#define NINJIN  2

#define DWIDTH          16
#define LWIDTH          10
#define IMGSIZE         16
#define RENKON_CORE     8
#define RENKON_NETSIZE  11
#define GOBOU_CORE      16
#define GOBOU_NETSIZE   13

#define RENKON_WORDS 2048
#define GOBOU_WORDS  8192

// TODO: is there needs to handle them with 'volatile'?
u32 *port                        = (void *)0x43c00000;
u32 *mem_image                   = (void *)0x83c00000;
u32 (*mem_renkon)[RENKON_WORDS]  = (void *)0x83c40000;
u32 (*mem_gobou)[GOBOU_WORDS]    = (void *)0x83c80000;

// input reg
#define reg_which       &port[0]
#define reg_req         &port[1]
#define reg_in_offset   &port[2]
#define reg_out_offset  &port[3]
#define reg_net_offset  &port[4]
#define reg_total_out   &port[5]
#define reg_total_in    &port[6]
#define reg_img_size    &port[7]
#define reg_fil_size    &port[8]
#define reg_pool_size   &port[9]

// output reg
#define reg_r_which     &port[31]
#define reg_ack         &port[30]

#endif
