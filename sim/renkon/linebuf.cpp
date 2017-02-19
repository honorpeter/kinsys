#include <cstdio>
#include <lib.hpp>

const int isize = 32;
const int fsize = 3;

int main(void)
{
  auto img = zeros<int16_t>(isize, isize);

  load(img, "../../data/renkon/input_linebuf.dat");

  for range(i, isize - fsize + 1)
  for range(j, isize - fsize + 1) {
    printf("Block %d:\n", (isize-fsize+1)*i+j);
    for range(di, fsize) {
      for range(dj, fsize)
        printf("%5d", img[i+di][j+dj]);
      printf("\n");
    }
    printf("\n");
  }

  return 0;
}
