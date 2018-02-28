#include <cstdio>
#include <lib.hpp>

const int isize = 32;
const int fsize = 5;

int main(void)
{
  using T = int32_t;

  const int feature = isize - fsize + 1;
  auto img = zeros<T>(isize, isize);

  load(img, "../../data/renkon/input_renkon_linebuf.dat");

  for range(i, feature)
  for range(j, feature) {
    printf("Block %d:\n", feature*i+j);
    for range(di, fsize) {
      for range(dj, fsize) {
        printf("%5d", img[i+di][j+dj]);
      }
      printf("\n");
    }
    printf("\n");
  }

  return 0;
}
