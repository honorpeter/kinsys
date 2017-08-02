#include <cstdio>
#include <lib.hpp>

const int isize = 32;
const int fsize = 5;
const int pad   = (fsize-1)/2;

int main(void)
{
  const int feature = isize + 2*pad - fsize + 1;
  auto img = zeros<int16_t>(isize, isize);

  load(img, "../../data/renkon/input_renkon_linebuf_pad.dat");

  for range(i, feature)
  for range(j, feature) {
    printf("Block %d:\n", feature*i+j);
    for range(di, fsize) {
      for range(dj, fsize) {
        const bool in_i = pad <= i+di && i+di < isize+pad;
        const bool in_j = pad <= j+dj && j+dj < isize+pad;
        const bool in_img = in_i && in_j;

        printf("%5d", in_img ? img[i+di-pad][j+dj-pad] : 0);
      }
      printf("\n");
    }
    printf("\n");
  }

  return 0;
}
