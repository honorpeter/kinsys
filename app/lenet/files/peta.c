#ifdef _PETA_H_

#include <string.h>
#include <stdlib.h>

#include <stdio.h>
#include <errno.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>

#include "kinpira.h"
#include "peta.h"

static int __port;
static int __mem_renkon;
static int __mem_gobou;

#include <assert.h>

// {{{
  // ref: http://blog.kmckk.com/archives/2897589.html
/* Performance Monitor Control Register of Cortex A9*/
#define PMCR_D 3
#define PMCR_C 2
#define PMCR_E 0
#define PMCNTENSET_C 31


volatile __inline__ static unsigned long __attribute__((always_inline))
pmon_start_cycle_counter()
{
  unsigned long x;

  x = 1 << PMCNTENSET_C;
  __asm__ __volatile__ ("mcr	p15, 0, %0, c9, c12, 1" :: "r" (x));
  __asm__ __volatile__ ("mrc	p15, 0, %0, c9, c12, 0" : "=r" (x));

  x |= ((1 << PMCR_D) | (1 << PMCR_C) | (1 << PMCR_E));
  __asm__ __volatile__ ("mcr	p15, 0, %0, c9, c12, 0" :: "r" (x));
  __asm__ __volatile__ ("mrc	p15, 0, %0, c9, c13, 0" : "=r" (x));

  return x;
}

volatile __inline__ static unsigned long __attribute__((always_inline))
pmon_read_cycle_counter()
{
  unsigned long x;
  __asm__ __volatile__ ("mrc	p15, 0, %0, c9, c13, 0": "=r" (x));

  return x;
}
// }}}

int kinpira_init(void)
{
  // Open Kinpira as UIO Driver
  __port       = open("/dev/uio0", O_RDWR);
  __mem_renkon = open("/dev/uio1", O_RDWR);
  __mem_gobou  = open("/dev/uio2", O_RDWR);

  if (__port < 0 || __mem_renkon < 0 || __mem_gobou < 0) {
    perror("uio open: ");
    return errno;
  }

  port       = mmap(NULL, sizeof(u32)*REGSIZE,
                    PROT_READ | PROT_WRITE, MAP_SHARED, __port, 0);

  mem_renkon = mmap(NULL, sizeof(u32)*RENKON_CORE*RENKON_WORDS,
                    PROT_READ | PROT_WRITE, MAP_SHARED, __mem_renkon, 0);

  mem_gobou  = mmap(NULL, sizeof(u32)*GOBOU_CORE*GOBOU_WORDS,
                    PROT_READ | PROT_WRITE, MAP_SHARED, __mem_gobou, 0);

  if (!port || !mem_renkon || !mem_gobou) {
    fprintf(stderr, "mmap failed\n");
    return errno;
  }

  system("modprobe switchdcache");

  return 0;
}



void define_2d(layer *l,
  s16 *in_offset, s16 *out_offset, u32 net_offset,
  u32 total_out, u32 total_in,
  u32 img_size, u32 fil_size, u32 pool_size
)
{
  l->which      = RENKON;
  l->in_offset  = (u32)(UINTPTR)in_offset;
  l->out_offset = (u32)(UINTPTR)out_offset;
  l->net_offset = net_offset;
  l->total_out  = total_out;
  l->total_in   = total_in;
  l->img_size   = img_size;
  l->fil_size   = fil_size;
  l->pool_size  = pool_size;
}



void assign_2d(layer *l, u32 *weight, u32 *bias)
{
  u32 idx_w = 0;
  u32 idx_b = 0;
  u32 idx   = l->net_offset;

  const u32 core  = RENKON_CORE;
  const u32 n_out = l->total_out;
  const u32 n_in  = l->total_in;
  const u32 fsize = l->fil_size;
  const u32 unit  = n_in * fsize * fsize;

  for (u32 n = 0; n < n_out/core; n++) {
    for (u32 dn = 0; dn < core; dn++) {
      memmove(&mem_renkon[dn][idx], &weight[idx_w], sizeof(u32)*unit);
      for (int i = 0; i < unit; i++)
        assert(mem_renkon[dn][idx+i] == weight[idx_w+i]);
      idx_w += unit;

      memmove(&mem_renkon[dn][idx+unit], &bias[idx_b], sizeof(u32)*1);
      assert(mem_renkon[dn][idx+unit] == bias[idx_b]);
      idx_b += 1;
    }

    idx += unit + 1;
  }

  if (n_out % core != 0) {
    for (u32 dn = 0; dn < core; dn++) {
      if (idx_b < n_out) {
        memmove(&mem_renkon[dn][idx], &weight[idx_w], sizeof(u32)*unit);
        for (int i = 0; i < unit; i++)
          assert(mem_renkon[dn][idx+i] == weight[idx_w+i]);
        idx_w += unit;

        memmove(&mem_renkon[dn][idx+unit], &bias[idx_b], sizeof(u32)*1);
        assert(mem_renkon[dn][idx+unit] == bias[idx_b]);
        idx_b += 1;
      }
      else {
        memset(&mem_renkon[dn][idx], 0, sizeof(u32)*(unit+1));
        for (int i = 0; i < unit+1; i++)
          assert(mem_renkon[dn][idx+i] == 0);
      }
    }

    idx += unit + 1;
  }
}



void define_1d(layer *l,
  s16 *in_offset, s16 *out_offset, u32 net_offset,
  u32 total_out, u32 total_in
)
{
  l->which      = GOBOU;
  l->in_offset  = (u32)(UINTPTR)in_offset;
  l->out_offset = (u32)(UINTPTR)out_offset;
  l->net_offset = net_offset;
  l->total_out  = total_out;
  l->total_in   = total_in;
  l->img_size   = 0;
  l->fil_size   = 0;
  l->pool_size  = 0;
}



void assign_1d(layer *l, u32 *weight, u32 *bias)
{
  u32 idx_w = 0;
  u32 idx_b = 0;
  u32 idx   = l->net_offset;

  const u32 core  = GOBOU_CORE;
  const u32 n_out = l->total_out;
  const u32 n_in  = l->total_in;

  for (u32 n = 0; n < n_out/core; n++) {
    for (u32 dn = 0; dn < core; dn++) {
      memmove(&mem_gobou[dn][idx], &weight[idx_w], sizeof(u32)*n_in);
      for (int i = 0; i < n_in; i++)
        assert(mem_gobou[dn][idx+i] == weight[idx_w+i]);
      idx_w += n_in;

      memmove(&mem_gobou[dn][idx+n_in], &bias[idx_b], sizeof(u32)*1);
      assert(mem_gobou[dn][idx+n_in] == bias[idx_b]);
      idx_b += 1;
    }

    idx += n_in + 1;
  }

  if (n_out % core != 0) {
    for (u32 dn = 0; dn < core; dn++) {
      if (idx_b < n_out) {
        memmove(&mem_gobou[dn][idx], &weight[idx_w], sizeof(u32)*n_in);
        for (int i = 0; i < n_in; i++)
          assert(mem_gobou[dn][idx+i] == weight[idx_w+i]);
        idx_w += n_in;

        memmove(&mem_gobou[dn][idx+n_in], &bias[idx_b], sizeof(u32)*1);
        assert(mem_gobou[dn][idx+n_in] == bias[idx_b]);
        idx_b += 1;
      }
      else {
        memset(&mem_gobou[dn][idx], 0, sizeof(u32)*(n_in+1));
        for (int i = 0; i < n_in+1; i++)
          assert(mem_gobou[dn][idx+i] == 0);
      }
    }

    idx += n_in + 1;
  }
}



void exec_core(layer *l)
{
  *reg_which      = l->which;
  *reg_req        = 0x0;
  *reg_in_offset  = l->in_offset;
  *reg_out_offset = l->out_offset;
  *reg_net_offset = l->net_offset;
  *reg_total_out  = l->total_out;
  *reg_total_in   = l->total_in;
  *reg_img_size   = l->img_size;
  *reg_fil_size   = l->fil_size;
  *reg_pool_size  = l->pool_size;

  *reg_pre_base   = l->in_offset;
  switch (l->which) {
    case RENKON:
      *reg_read_len   = l->total_in * l->img_size * l->img_size;
      *reg_write_len  = (l->total_out < RENKON_CORE ? l->total_out : RENKON_CORE)
                      * ((l->img_size - l->fil_size + 1)/(l->pool_size))
                      * ((l->img_size - l->fil_size + 1)/(l->pool_size));
      break;
    case GOBOU:
      *reg_read_len   = l->total_in;
      *reg_write_len  = l->total_out < GOBOU_CORE ? l->total_out : GOBOU_CORE;
      break;
    default:
      *reg_read_len   = 0;
      *reg_write_len  = 0;
      break;
  }

  *reg_pre_req = 1;
  *reg_pre_req = 0;

  do {
    // Nop
  } while (!*reg_pre_ack);


  *reg_req = 0x1;
  *reg_req = 0x0;

  // Blocking till PL finishing the operation
  do {
    // Nop
  } while (!*reg_ack);
}

int kinpira_exit(void)
{
  system("modprobe -r switchdcache");

  munmap(port, sizeof(u32)*REGSIZE);
  munmap(mem_renkon, sizeof(u32)*RENKON_CORE*RENKON_WORDS);
  munmap(mem_gobou, sizeof(u32)*GOBOU_CORE*GOBOU_WORDS);

  close(__port);
  close(__mem_renkon);
  close(__mem_gobou);

  return 0;
}



void print_result(s16 *output, const u32 length)
{
  int number  = -1;
  int max     = output[0];

  for (int i = 0; i < length; i++) {
    printf("%d: %d\n", i, output[i]);

    if (max < output[i]) {
      max = output[i];
      number = i;
    }
  }

  printf("the answer is %d.\n", number);
}



void print_port()
{
  printf(
    "&port[0]:  %08x &port[1]:  %08x &port[2]:  %08x &port[3]:  %08x\n"
    "&port[4]:  %08x &port[5]:  %08x &port[6]:  %08x &port[7]:  %08x\n"
    "&port[8]:  %08x &port[9]:  %08x &port[10]: %08x &port[11]: %08x\n"
    "&port[12]: %08x &port[13]: %08x &port[14]: %08x &port[15]: %08x\n"
    "&port[16]: %08x &port[17]: %08x &port[18]: %08x &port[19]: %08x\n"
    "&port[20]: %08x &port[21]: %08x &port[22]: %08x &port[23]: %08x\n"
    "&port[24]: %08x &port[25]: %08x &port[26]: %08x &port[27]: %08x\n"
    "&port[28]: %08x &port[29]: %08x &port[30]: %08x &port[31]: %08x\n"
    , port[0], port[1], port[2], port[3]
    , port[4], port[5], port[6], port[7]
    , port[8], port[9], port[10], port[11]
    , port[12], port[13], port[14], port[15]
    , port[16], port[17], port[18], port[19]
    , port[20], port[21], port[22], port[23]
    , port[24], port[25], port[26], port[27]
    , port[28], port[29], port[30], port[31]
  );
}



#endif
