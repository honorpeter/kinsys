#include <cstdio>
#include <lib.hpp>

const int height  = 12;
const int width   = 16;
const int kern    = 3;
const int stride  = 1;
const int pad     = 0;
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
  using T = int16_t;

  int fea_h = make_size(height, kern, stride, pad, cover_all);
  int fea_w = make_size(width, kern, stride, pad, cover_all);

  auto img = zeros<T>(height, width);
  auto img_pad = zeros<T>(fea_h+kern-1, fea_w+kern-1);

  load(img, "../../data/renkon/input_renkon_linebuf_pad.dat");
  for range(i, height)
  for range(j, width)
    img_pad[i+pad][j+pad] = img[i][j];

  int idx = 0;
  for ranges(i, fea_h, stride)
  for ranges(j, fea_w, stride) {
    printf("Block %d:\n", idx++);
    for range(di, 3-kern) {
      for range(dj, 3-kern)
        printf("%5d", 0);
      for range(dj, kern) {
        printf("%5d", 0);
      }
      printf("\n");
    }
    for range(di, kern) {
      for range(dj, 3-kern)
        printf("%5d", 0);
      for range(dj, kern) {
        printf("%5d", img_pad[i+di][j+dj]);
      }
      printf("\n");
    }
    printf("\n");
  }

  return 0;
}
