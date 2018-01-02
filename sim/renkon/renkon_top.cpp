#include <cstdio>
#include <cfloat>
#include <cmath>
#include <iostream>
#include <limits>
#include <lib.hpp>

// const int n_out     = 32;
// const int n_in      = 16;
const int img_size  = 12;
const int n_out = 16;
const int n_in  = 1;
// const int img_size = 28;

int make_size(int size, int kern, int stride, int pad, bool cover_all=false)
{
  if (cover_all)
    return (size + pad * 2 - kern + stride - 1) / stride + 1;
  else
    return (size + pad * 2 - kern) / stride + 1;
}

const int conv_kern   = 3;
const int conv_stride = 1;
const int conv_pad    = 1;
const int fea_size    = make_size(img_size, conv_kern, conv_stride, conv_pad);
const int pool_kern   = 2;
const int pool_stride = 2;
const int pool_pad    = 0;
const int out_size    = make_size(fea_size, pool_kern, pool_stride, pool_pad,
                                  true);

template <typename T>
T mul(T x, T y)
{
  int prod = x * y;

  if (prod >= 0)
    return prod / static_cast<T>(pow(2, 8));
  else
    return prod / static_cast<T>(pow(2, 8)) - 1;
}

template <typename T>
void conv(Mat3D<T> &output, Mat3D<T> &input, Mat4D<T> &weight)
{
  auto padded = zeros<T>(n_in, img_size+2*conv_pad, img_size+2*conv_pad);
  // auto padded = zeros<T>(n_in, img_size+2*conv_pad+conv_stride-1,
  //                              img_size+2*conv_pad+conv_stride-1);

  for range(n, n_in)
  for range(i, img_size)
  for range(j, img_size)
    padded[n][i+conv_pad][j+conv_pad] = input[n][i][j];

  for range(n, n_out)
  for ranges(i, img_size+2*conv_pad-conv_kern+1, conv_stride)
  for ranges(j, img_size+2*conv_pad-conv_kern+1, conv_stride) {
    T acc = 0;
    for range(m, n_in)
    for range(di, conv_kern)
    for range(dj, conv_kern)
      acc += mul<T>(padded[m][i+di][j+dj], weight[n][m][di][dj]);
    output[n][i/conv_stride][j/conv_stride] = acc;
  }
}

template <typename T>
void bias(Mat3D<T> &output, Mat3D<T> &input, Mat1D<T> bias)
{
  for range(n, n_out)
  for range(i, fea_size)
  for range(j, fea_size)
    output[n][i][j] = input[n][i][j] + bias[n];
}

template <typename T>
void relu(Mat3D<T> &output, Mat3D<T> &input)
{
  for range(n, n_out)
  for range(i, fea_size)
  for range(j, fea_size)
    if (input[n][i][j] > 0)
      output[n][i][j] = input[n][i][j];
    else
      output[n][i][j] = 0;
}

template <typename T>
void pool(Mat3D<T> &output, Mat3D<T> &input)
{
  auto padded = zeros<T>(n_out, fea_size+2*pool_pad+pool_stride-1,
                                fea_size+2*pool_pad+pool_stride-1);

  for range(n, n_out)
  for range(i, fea_size)
  for range(j, fea_size)
    padded[n][i+pool_pad][j+pool_pad] = input[n][i][j];

  for range(n, n_out)
  for ranges(i, fea_size, pool_stride)
  for ranges(j, fea_size, pool_stride) {
    T tmp = std::numeric_limits<T>::min();
    for range(di, pool_kern)
    for range(dj, pool_kern)
      if (padded[n][i+di][j+dj] > tmp)
        tmp = padded[n][i+di][j+dj];
    output[n][i/pool_stride][j/pool_stride] = tmp;
  }
}

int main(void)
{
  auto input  = zeros<int16_t>(n_in,  img_size, img_size);
  auto fmap   = zeros<int16_t>(n_out, fea_size, fea_size);
  auto bmap   = zeros<int16_t>(n_out, fea_size, fea_size);
  auto amap   = zeros<int16_t>(n_out, fea_size, fea_size);
  auto pmap   = zeros<int16_t>(n_out, out_size, out_size);

  auto W = zeros<int16_t>(n_out, n_in, conv_kern, conv_kern);
  auto b = zeros<int16_t>(n_out);

  load(input, "../../data/renkon/input_renkon_top.dat");
  load(W, "../../data/renkon/weight_renkon_top.dat");
  load(b, "../../data/renkon/bias_renkon_top.dat");

  conv(fmap, input, W);
  bias(bmap, fmap, b);
  relu(amap, bmap);
  pool(pmap, amap);

  for range(n, n_out)
    for range(i, out_size)
      for range(j, out_size)
        printf("%d\n", pmap[n][i][j]);

  // for range(n, n_out) {
  //   for range(i, fea_size) {
  //     for range(j, fea_size) {
  //       fprintf(stderr, "%d\n", amap[n][i][j]);
  //     }
  //     fprintf(stderr, "\n");
  //   }
  //   fprintf(stderr, "\n");
  // }

  // for range(n, n_out)
  //   for range(i, fea_size)
  //     for range(j, fea_size)
  //       printf("%d\n", amap[n][i][j]);

  return 0;
}
