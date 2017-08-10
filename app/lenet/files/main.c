#include <stdio.h>

#include "kinpira.h"
#include "peta.h"

#include "lenet.h"

#include "data/image.h"
#include "data/W_conv0.h"
#include "data/b_conv0.h"
#include "data/W_conv1.h"
#include "data/b_conv1.h"
#include "data/W_full2.h"
#include "data/b_full2.h"
#include "data/W_full3.h"
#include "data/b_full3.h"

#include "data/conv0_tru.h"
#include "data/conv1_tru.h"
#include "data/full2_tru.h"
#include "data/full3_tru.h"

// latency analysis
#include <time.h>
#define INIT  clock_t begin, end;
#define BEGIN begin = clock();
#define END   do {                                     \
  end = clock();                                       \
  printf("%12.6f [us]\n\n",                            \
      (double)(end-begin) / CLOCKS_PER_SEC * 1000000); \
} while (0);

// #include <assert.h>
#define assert_eq(a, b) do {                                      \
  if ((a) != (b)) {                                               \
    printf("Assertion failed: %s == %s, file %s, line %d\n",      \
            #a, #b, __FILE__, __LINE__);                          \
    printf("\t%s == %x, %s == %x\n", #a, (u32)(a), #b, (u32)(b)); \
    return 1;                                                     \
  }                                                               \
} while (0)

#define assert_not(cond, fail_msg) do {                 \
  if ((cond)) {                                         \
    printf("Assertion failed: %s, file %s, line %d\n",  \
            (fail_msg), __FILE__, __LINE__);            \
    return 1;                                           \
  }                                                     \
} while (0)


int main(void)
{
  INIT

  layer conv0, conv1;
  layer full2, full3;

  // Create udmabuf
  system("modprobe udmabuf udmabuf0=1048576");
  int fd;
  char attr[1024];
  u32 phys_addr;
  if ((fd = open("/sys/class/udmabuf/udmabuf0/phys_addr", O_RDONLY)) == -1) {
      puts("file open error.");
      exit(-1);
  }
  read(fd, attr, 1024);
  sscanf(attr, "%x", &phys_addr);
  close(fd);
  printf("udmabuf created at: %x.\n", phys_addr);

  // Copy image -> udmabuf
  const int image_size = ISIZE * ISIZE;
  const int imagebuf_size = sizeof(s16)*ISIZE*ISIZE;
  int o_sync = O_SYNC; // disable cache
  if ((fd = open("/dev/udmabuf0", O_RDWR | o_sync)) == -1) {
      puts("udmabuf open error.");
      exit(-1);
  }
  s16* imagebuf = mmap(NULL, imagebuf_size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
  memcpy(imagebuf, image, imagebuf_size);
  for (int i = 0; i < image_size; i++)
      assert(imagebuf[i] == image[i]);

  // NOTE: maps could be multi dimentional array
  const int pmap0_size = sizeof(s16)*N_C0*PM0SIZE*PM0SIZE;
  const int pmap1_size = sizeof(s16)*N_C1*PM1SIZE*PM1SIZE;
  const int fvec2_size = sizeof(s16)*N_F2;
  const int fvec3_size = sizeof(s16)*N_F3;
  const int pagesize = sysconf(_SC_PAGESIZE);
  const int pmap0_offset = (imagebuf_size / pagesize + 1) * pagesize;
  const int pmap1_offset = pmap0_offset + (pmap0_size / pagesize + 1) * pagesize;
  const int fvec2_offset = pmap1_offset + (pmap1_size / pagesize + 1) * pagesize;
  const int fvec3_offset = fvec2_offset + (fvec2_size / pagesize + 1) * pagesize;
  s16 *pmap0 = mmap(NULL, pmap0_size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, pmap0_offset);
  s16 *pmap1 = mmap(NULL, pmap1_size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, pmap1_offset);
  s16 *fvec2 = mmap(NULL, fvec2_size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, fvec2_offset);
  s16 *fvec3 = mmap(NULL, fvec3_size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, fvec3_offset);

  setbuf(stdout, NULL);
  printf("\033[2J");
  puts("### start lenet application:");

  assert_not(!pmap0, "pmap0 mmap failed");
  assert_not(!pmap1, "pmap1 mmap failed");
  assert_not(!fvec2, "fvec2 mmap failed");
  assert_not(!fvec3, "fvec3 mmap failed");

  const u32 image_phys_addr = phys_addr;
  const u32 pmap0_phys_addr = phys_addr + pmap0_offset;
  const u32 pmap1_phys_addr = phys_addr + pmap1_offset;
  const u32 fvec2_phys_addr = phys_addr + fvec2_offset;
  const u32 fvec3_phys_addr = phys_addr + fvec3_offset;

  define_2d(&conv0, image_phys_addr, pmap0_phys_addr, CONV0_PARAM,
            N_C0, N_IN, ISIZE, FSIZE, PSIZE);

  define_2d(&conv1, pmap0_phys_addr, pmap1_phys_addr, CONV1_PARAM,
            N_C1, N_C0, PM0SIZE, FSIZE, PSIZE);

  define_1d(&full2, pmap1_phys_addr, fvec2_phys_addr, FULL2_PARAM,
            N_F2, N_C1*PM1SIZE*PM1SIZE);

  define_1d(&full3, fvec2_phys_addr, fvec3_phys_addr, FULL3_PARAM,
            N_F3, N_F2);

  kinpira_init();

  assign_2d(&conv0, W_conv0, b_conv0);
  assign_2d(&conv1, W_conv1, b_conv1);
  assign_1d(&full2, W_full2, b_full2);
  assign_1d(&full3, W_full3, b_full3);

  puts("exec_core(&conv0)");
  BEGIN
  exec_core(&conv0);
  END

  puts("exec_core(&conv1)");
  BEGIN
  exec_core(&conv1);
  END

  puts("exec_core(&full2)");
  BEGIN
  exec_core(&full2);
  END

  puts("exec_core(&full3)");
  BEGIN
  exec_core(&full3);
  END

  kinpira_exit();

  print_result(fvec3, LABEL);

  puts("");
  for (int i = 0; i < N_C0*PM0SIZE*PM0SIZE; i++)
    assert_eq(pmap0[i], conv0_tru[i]);
  puts("conv0 assert ok");

  for (int i = 0; i < N_C1*PM1SIZE*PM1SIZE; i++)
    assert_eq(pmap1[i], conv1_tru[i]);
  puts("conv1 assert ok");

  for (int i = 0; i < N_F2; i++)
    assert_eq(fvec2[i], full2_tru[i]);
  puts("full2 assert ok");

  for (int i = 0; i < N_F3; i++)
    assert_eq(fvec3[i], full3_tru[i]);
  puts("full3 assert ok");


  // Delete udmabuf
  munmap(imagebuf, image_size);
  munmap(pmap0, pmap0_size);
  munmap(pmap1, pmap1_size);
  munmap(fvec2, fvec2_size);
  munmap(fvec3, fvec3_size);
  close(fd);
  system("modprobe -r udmabuf");

  return 0;
}
