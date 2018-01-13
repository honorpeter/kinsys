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
  system("modprobe udmabuf udmabuf0=1048576");
  system("modprobe uio_pdrv_genirq");
  sleep(1);

  // Create udmabuf
  int fd;
  char attr[1024];

  fd = open("/sys/class/udmabuf/udmabuf0/phys_addr", O_RDONLY);
  if (fd < 0) {
    perror("phys_addr open error");
    return errno;
  }

  read(fd, attr, 1024);
  sscanf(attr, "%x", &phys_addr);
  close(fd);

  udmabuf0 = open("/dev/udmabuf0", O_RDWR | O_SYNC);
  if (udmabuf0 < 0) {
    perror("udmabuf open error");
    return errno;
  }

  pagesize = sysconf(_SC_PAGESIZE);
  offset   = 0;

  // Open Kinpira as UIO Driver
  __port       = open("/dev/uio0", O_RDWR);
  __mem_renkon = open("/dev/uio1", O_RDWR);
  __mem_gobou  = open("/dev/uio2", O_RDWR);

  if (__port < 0 || __mem_renkon < 0 || __mem_gobou < 0) {
    perror("uio open");
    return errno;
  }

  port = (u32 *)mmap(NULL, sizeof(u32)*REGSIZE,
                     PROT_READ | PROT_WRITE, MAP_SHARED,
                     __port, 0);

  mem_renkon =
    (u32 (*)[RENKON_WORDS])mmap(NULL, sizeof(u32)*RENKON_CORE*RENKON_WORDS,
                                PROT_READ | PROT_WRITE, MAP_SHARED,
                                __mem_renkon, 0);

  mem_gobou =
    (u32 (*)[GOBOU_WORDS])mmap(NULL, sizeof(u32)*GOBOU_CORE*GOBOU_WORDS,
                               PROT_READ | PROT_WRITE, MAP_SHARED,
                               __mem_gobou, 0);

  if (!port || !mem_renkon || !mem_gobou) {
    fprintf(stderr, "mmap failed\n");
    return errno;
  }

  return 0;
}



int kinpira_exit(void)
{
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



Map *define_map(int map_c, int map_w, int map_h)
{
  Map *r = (Map *)malloc(sizeof(Map));

  r->shape[0] = map_c;
  r->shape[1] = map_w;
  r->shape[2] = map_h;

  int map_size = sizeof(s16)*map_c*map_w*map_h;

  r->body = (s16 *)mmap(NULL, map_size,
                        PROT_READ | PROT_WRITE, MAP_SHARED,
                        udmabuf0, offset);

  r->phys_addr = phys_addr + offset;

  offset += (map_size / pagesize + 1) * pagesize;

  return r;
}



Vec *define_vec(int vec_l)
{
  Vec *r = (Vec *)malloc(sizeof(Vec));

  r->shape = vec_l;

  int vec_size = sizeof(s16)*vec_l;

  r->body = (s16 *)mmap(NULL, vec_size,
                        PROT_READ | PROT_WRITE, MAP_SHARED,
                        udmabuf0, offset);

  r->phys_addr = phys_addr + offset;

  offset += (vec_size / pagesize + 1) * pagesize;

  return r;
}



void undef_map(Map *r)
{
  munmap(r->body, sizeof(s16)*r->shape[0]*r->shape[1]*r->shape[2]);
  free(r);
}



void undef_vec(Vec *r)
{
  munmap(r->body, sizeof(s16)*r->shape);
  free(r);
}



