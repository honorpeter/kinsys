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

// #define PAGED
// #define __KPR_RELEASE__
#define __KPR_DEBUG__



#ifdef __KPR_RELEASE__
static int __port;
static int __mem_renkon;
static int __mem_gobou;
static int __mem_image;
#endif



#ifdef PAGED
static int pagesize;
#endif

static u32 phys_addr;
static u32 offset;

int kinpira_init(void)
{
#ifdef __KPR_RELEASE__
  system("modprobe uio_pdrv_genirq");
  system("modprobe udmabuf udmabuf0=4194304");
  sleep(1);

  // Open Kinpira slave ports as UIO driver
  __port       = open("/dev/uio0", O_RDWR);
  __mem_renkon = open("/dev/uio1", O_RDWR);
  __mem_gobou  = open("/dev/uio2", O_RDWR);
  if (__port < 0 || __mem_renkon < 0 || __mem_gobou < 0) {
    perror("uio open error");
    return errno;
  }

  // Open Kinpira master ports as udmabuf
  __mem_image  = open("/dev/udmabuf0", O_RDWR | O_SYNC);
  if (__mem_image < 0) {
    perror("udmabuf open error");
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

  mem_image = (s16 *)mmap(NULL, 4194304,
                          PROT_READ | PROT_WRITE, MAP_SHARED,
                          __mem_image, 0);

  if (!port || !mem_renkon || !mem_gobou || !mem_image) {
    fprintf(stderr, "mmap failed\n");
    return errno;
  }

  int fd = open("/sys/class/udmabuf/udmabuf0/phys_addr", O_RDONLY);
  if (fd < 0) {
    perror("phys_addr open error");
    return errno;
  }
  char attr[1024];
  read(fd, attr, 1024);
  sscanf(attr, "%x", &phys_addr);
  close(fd);
#else
  port = (u32 *)malloc(sizeof(u32)*REGSIZE);

  mem_renkon =
    (u32 (*)[RENKON_WORDS])malloc(sizeof(u32)*RENKON_CORE*RENKON_WORDS);

  mem_gobou =
    (u32 (*)[GOBOU_WORDS])malloc(sizeof(u32)*GOBOU_CORE*GOBOU_WORDS);

  mem_image = (s16 *)malloc(sizeof(s16)*4194304*5);
#endif

#ifdef PAGED
  pagesize = sysconf(_SC_PAGESIZE);
#endif
  offset   = 0;

  return 0;
}



int kinpira_exit(void)
{
#ifdef __KPR_RELEASE__
  munmap(port, sizeof(u32)*REGSIZE);
  munmap(mem_renkon, sizeof(u32)*RENKON_CORE*RENKON_WORDS);
  munmap(mem_gobou, sizeof(u32)*GOBOU_CORE*GOBOU_WORDS);
  munmap(mem_image, sizeof(s16)*4194304);

  close(__port);
  close(__mem_renkon);
  close(__mem_gobou);
  close(__mem_image);
#else
  free(port);
  free(mem_renkon);
  free(mem_gobou);
  free(mem_image);
#endif

  // system("modprobe -r udmabuf");
  // system("modprobe -r uio_pdrv_genirq");

  return 0;
}



Map *define_map(int qbits, int map_c, int map_h, int map_w)
{
  Map *r = (Map *)malloc(sizeof(Map));

  r->qbits = qbits;

  r->shape[0] = map_c;
  r->shape[1] = map_h;
  r->shape[2] = map_w;

  int map_size = sizeof(s16)*map_c*map_h*map_w;

  r->phys_addr = phys_addr + offset;
  r->body = (s16 *)((UINTPTR)mem_image + offset);

#ifdef __KPR_DEBUG__
  printf("offset: %lu\n", offset);
#endif

#ifdef PAGED
  offset += (map_size / pagesize + 1) * pagesize;
#else
  offset += map_size;
#endif

  return r;
}



Vec *define_vec(int qbits, int vec_l)
{
  Vec *r = (Vec *)malloc(sizeof(Vec));

  r->qbits = qbits;

  r->shape = vec_l;

  int vec_size = sizeof(s16)*vec_l;

  r->phys_addr = phys_addr + offset;
  r->body = (s16 *)((UINTPTR)mem_image + offset);

#ifdef __KPR_DEBUG__
  printf("offset: %lu\n", offset);
#endif

#ifdef PAGED
  offset += (vec_size / pagesize + 1) * pagesize;
#else
  offset += vec_size;
#endif

  return r;
}



void undef_map(Map *r)
{
  free(r);
}



void undef_vec(Vec *r)
{
  free(r);
}



