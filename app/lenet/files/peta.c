#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>

#include "peta.h"
#include "kinpira.h"
#include "types.h"

#include <stdio.h>
#include <errno.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>



static int __port;
static int __mem_renkon;
static int __mem_gobou;
static int udmabuf0;



static int pagesize;

static u32 phys_addr;
static u32 offset;

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

  // system("modprobe -r udmabuf");
  // system("modprobe -r uio_pdrv_genirq");

  return 0;
}



map *define_map(int map_c, int map_w, int map_h)
{
  map *r = malloc(sizeof(map));

  r->shape[0] = map_c;
  r->shape[1] = map_w;
  r->shape[2] = map_h;

  int map_size = sizeof(s16)*map_c*map_w*map_h;

  r->body = mmap(NULL, map_size,
                 PROT_READ | PROT_WRITE, MAP_SHARED,
                 udmabuf0, offset);

  r->phys_addr = phys_addr + offset;

  offset += (map_size / pagesize + 1) * pagesize;

  return r;
}



vec *define_vec(int vec_l)
{
  vec *r = malloc(sizeof(vec));

  r->shape = vec_l;

  int vec_size = sizeof(s16)*vec_l;

  r->body = mmap(NULL, vec_size,
                 PROT_READ | PROT_WRITE, MAP_SHARED,
                 udmabuf0, offset);

  r->phys_addr = phys_addr + offset;

  offset += (vec_size / pagesize + 1) * pagesize;

  return r;
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



