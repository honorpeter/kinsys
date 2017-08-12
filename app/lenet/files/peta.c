#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>

#include <stdio.h>
#include <errno.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>

#include "kinpira.h"
#include "types.h"
#include "peta.h"

#include <assert.h>

static int __port;
static int __mem_renkon;
static int __mem_gobou;
static int udmabuf0;


static int pagesize;

static u32 phys_addr;
static u32 offset;

static u32 bit(u32 value, int high, int low)
{
  return value << (31-high) >> (31-high) >> low;
}



int kinpira_init(void)
{
  system("modprobe uio_pdrv_genirq");

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

  // Create udmabuf
  int fd;
  char attr[1024];

  system("modprobe udmabuf udmabuf0=1048576");

  fd = open("/sys/class/udmabuf/udmabuf0/phys_addr", O_RDONLY);
  if (fd < 0) {
    perror("phys_addr open error: ");
    return errno;
  }

  read(fd, attr, 1024);
  sscanf(attr, "%x", &phys_addr);
  close(fd);

  // int o_sync = O_SYNC; // disable cache
  // if ((udmabuf0 = open("/dev/udmabuf0", O_RDWR | o_sync)) == -1) {
  udmabuf0 = open("/dev/udmabuf0", O_RDWR | O_SYNC);
  if (udmabuf0 < 0) {
    perror("udmabuf open error: ");
    return errno;
  }

  pagesize = sysconf(_SC_PAGESIZE);
  offset   = 0;

  // TODO: remove switchdcache
  // system("modprobe switchdcache");

  return 0;
}



int kinpira_exit(void)
{
  // TODO: remove switchdcache
  // system("modprobe -r switchdcache");

  munmap(port, sizeof(u32)*REGSIZE);
  munmap(mem_renkon, sizeof(u32)*RENKON_CORE*RENKON_WORDS);
  munmap(mem_gobou, sizeof(u32)*GOBOU_CORE*GOBOU_WORDS);

  close(__port);
  close(__mem_renkon);
  close(__mem_gobou);

  close(udmabuf0);

  system("modprobe -r udmabuf");
  system("modprobe -r uio_pdrv_genirq");

  return 0;
}



map *define_map(int map_c, int map_w, int map_h)
{
  map *r = malloc(sizeof(map));

  r->shape[0] = map_c;
  r->shape[1] = map_w;
  r->shape[2] = map_h;

  int map_size = sizeof(s16)*map_c*map_w*map_h;

  r->phys_addr = phys_addr + offset;

  r->body = mmap(NULL, map_size,
                 PROT_READ | PROT_WRITE, MAP_SHARED,
                 udmabuf0, offset);

  offset += (map_size / pagesize + 1) * pagesize;

  return r;
}



vec *define_vec(int vec_l)
{
  vec *r = malloc(sizeof(vec));

  r->shape = vec_l;

  int vec_size = sizeof(s16)*vec_l;

  r->phys_addr = phys_addr + offset;

  r->body = mmap(NULL, vec_size,
                 PROT_READ | PROT_WRITE, MAP_SHARED,
                 udmabuf0, offset);

  offset += (vec_size / pagesize + 1) * pagesize;

  return r;
}



void assign_map(layer *l, u32 *weight, u32 *bias)
{
  const u32 core  = RENKON_CORE;
  const u32 n_out = bit(l->base_param[0], 2*LWIDTH-1, LWIDTH);
  const u32 n_in  = bit(l->base_param[0], LWIDTH-1, 0);
  const u32 fsize = bit(l->conv_param, 2*LWIDTH-1, LWIDTH);
  const u32 unit  = n_in * fsize * fsize;

  u32 idx_w = 0;
  u32 idx_b = 0;
  u32 idx   = l->net_offset;

  for (u32 n = 0; n < n_out/core; n++) {
    for (u32 dn = 0; dn < core; dn++) {
      memmove(&mem_renkon[dn][idx], &weight[idx_w], sizeof(u32)*unit);
      idx_w += unit;

      memmove(&mem_renkon[dn][idx+unit], &bias[idx_b], sizeof(u32)*1);
      idx_b += 1;
    }

    idx += unit + 1;
  }

  if (n_out % core != 0) {
    for (u32 dn = 0; dn < core; dn++) {
      if (idx_b < n_out) {
        memmove(&mem_renkon[dn][idx], &weight[idx_w], sizeof(u32)*unit);
        idx_w += unit;

        memmove(&mem_renkon[dn][idx+unit], &bias[idx_b], sizeof(u32)*1);
        idx_b += 1;
      }
      else {
        memset(&mem_renkon[dn][idx], 0, sizeof(u32)*(unit+1));
      }
    }

    idx += unit + 1;
  }
}



void assign_vec(layer *l, u32 *weight, u32 *bias)
{
  const u32 core  = GOBOU_CORE;
  const u32 n_out = bit(l->base_param[0], 2*LWIDTH-1, LWIDTH);
  const u32 n_in  = bit(l->base_param[0], LWIDTH-1, 0);

  u32 idx_w = 0;
  u32 idx_b = 0;
  u32 idx   = l->net_offset;

  for (u32 n = 0; n < n_out/core; n++) {
    for (u32 dn = 0; dn < core; dn++) {
      memmove(&mem_gobou[dn][idx], &weight[idx_w], sizeof(u32)*n_in);
      idx_w += n_in;

      memmove(&mem_gobou[dn][idx+n_in], &bias[idx_b], sizeof(u32)*1);
      idx_b += 1;
    }

    idx += n_in + 1;
  }

  if (n_out % core != 0) {
    for (u32 dn = 0; dn < core; dn++) {
      if (idx_b < n_out) {
        memmove(&mem_gobou[dn][idx], &weight[idx_w], sizeof(u32)*n_in);
        idx_w += n_in;

        memmove(&mem_gobou[dn][idx+n_in], &bias[idx_b], sizeof(u32)*1);
        idx_b += 1;
      }
      else {
        memset(&mem_gobou[dn][idx], 0, sizeof(u32)*(n_in+1));
      }
    }

    idx += n_in + 1;
  }
}



void undef_map(map *r)
{
  munmap(r->body, sizeof(s16)*r->shape[0]*r->shape[1]*r->shape[2]);
  free(r);
}



void undef_vec(vec *r)
{
  munmap(r->body, sizeof(s16)*r->shape);
  free(r);
}



void exec_core(layer *l)
{
  *reg_which        = l->which;
  *reg_in_offset    = l->in_offset;
  *reg_out_offset   = l->out_offset;
  *reg_net_offset   = l->net_offset;

  *reg_pre_base     = l->in_offset;
  *reg_read_len     = l->read_len;
  *reg_write_len    = l->write_len;

  *reg_base_param0  = l->base_param[0];
  *reg_base_param1  = l->base_param[1];
  *reg_conv_param   = l->conv_param;
  *reg_bias_param   = l->bias_param;
  // *reg_norm_param = l->norm_param;
  *reg_actv_param   = l->actv_param;
  *reg_pool_param   = l->pool_param;

  *reg_pre_req = 1;
  *reg_pre_req = 0;
  do {
    // Nop
  } while (!*reg_pre_ack);


  *reg_req = 0x1;
  *reg_req = 0x0;
  do {
    // Nop
  } while (!*reg_ack);
}

