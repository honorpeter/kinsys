#include <cstdio>
#include <lib.hpp>

const int size    = 12;
const int kern    = 2;
const int stride  = 2;
const int pad     = 0;// (kern-1)/2;
const bool cover_all = false;

int make_size(int size, int kern, int stride, int pad, bool cover_all=false)
{
  if (cover_all)
    return size + pad * 2 - kern + stride;
  else
    return size + pad * 2 - kern + 1;
}

int make_after(int size, int kern, int stride, int pad, bool cover_all=false)
{
  return (make_size(size, kern, stride, pad, cover_all) - 1) / stride + 1;
}

int main(void)
{
  // const int feature = size + 2*pad - kern + 1;
  int feature = make_size(size, kern, stride, pad, cover_all);
  auto img = zeros<int16_t>(size, size);
  // auto img_pad = zeros<int16_t>(size+2*pad+stride-1, size+2*pad+stride-1);
  auto img_pad = zeros<int16_t>(feature+kern-1, feature+kern-1);

  load(img, "../../data/renkon/input_renkon_linebuf_pad.dat");
  for range(i, size)
  for range(j, size)
    img_pad[i+pad][j+pad] = img[i][j];

  int idx = 0;
  for ranges(i, feature, stride)
  for ranges(j, feature, stride) {
    printf("Block %d:\n", idx++);
    for range(di, kern) {
      for range(dj, kern) {
        printf("%5d", img_pad[i+di][j+dj]);
      }
      printf("\n");
    }
    printf("\n");
  }

  return 0;
}
