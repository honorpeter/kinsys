#ifndef _KINPIRA_H_
#define _KINPIRA_H_

// #define KINPIRA_AXI
#define KINPIRA_DDR

#include "xil_types.h"

#define RENKON  0
#define GOBOU   1
#define NINJIN  2

#define DWIDTH          16
#if defined(KINPIRA_AXI)
# define LWIDTH          10
#elif defined (KINPIRA_DDR)
# define LWIDTH          16
#endif
#define IMGSIZE         16
#define RENKON_CORE     8
#define RENKON_NETSIZE  11
#define GOBOU_CORE      16
#define GOBOU_NETSIZE   13

#define RENKON_WORDS 2048
#define GOBOU_WORDS  8192

#if defined(KINPIRA_AXI)
u32 *port                        = (void *)0x43c00000;
u32 *mem_image                   = (void *)0x83c00000;
u32 (*mem_renkon)[RENKON_WORDS]  = (void *)0x83c40000;
u32 (*mem_gobou)[GOBOU_WORDS]    = (void *)0x83c80000;
#elif defined(KINPIRA_DDR)
u32 *port                        = (void *)0x43c00000;
// u32 *mem_image                   = (void *)0x83c00000;
u32 (*mem_renkon)[RENKON_WORDS]  = (void *)0x83c00000;
u32 (*mem_gobou)[GOBOU_WORDS]    = (void *)0x83c80000;
#endif

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
#ifdef KINPIRA_DDR
# define reg_pre_en      &port[10]
# define reg_pre_base    &port[11]
# define reg_read_len    &port[12]
# define reg_write_len   &port[13]
#endif

// output reg
#define reg_r_which     &port[31]
#define reg_ack         &port[30]

#endif
