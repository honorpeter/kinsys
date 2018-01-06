#include <cstdio>
#include <cfloat>
#include <cmath>
#include <iostream>
#include <limits>
#include <lib.hpp>

// const int n_out     = 32;
// const int n_in      = 16;
const int img_height  = 12;
const int img_width   = 16;
const int n_out       = 16;
const int n_in        = 1;
// const int img_height  = 28;
// const int img_width   = 28;
const int qbits = 8;

int make_size(int size, int kern, int strid, int pad, bool cover_all=false)
{
  if (cover_all)
    return (size + pad * 2 - kern + strid - 1) / strid + 1;
  else
    return (size + pad * 2 - kern) / strid + 1;
}

const int conv_kern   = 1;
const int conv_strid  = 1;
const int conv_pad    = 0;
const int fea_height  = make_size(img_height, conv_kern, conv_strid, conv_pad);
const int fea_width   = make_size(img_width, conv_kern, conv_strid, conv_pad);
const int pool_kern   = 2;
const int pool_strid  = 2;
const int pool_pad    = 0;
const int out_height  = make_size(fea_height, pool_kern, pool_strid, pool_pad,
                                  true);
const int out_width   = make_size(fea_width, pool_kern, pool_strid, pool_pad,
                                  true);

template <typename T>
T mul(T x, T y)
{
  int prod = x * y;

  if (prod < 0)
    // return prod / static_cast<T>(pow(2, 8)) - 1;
    return (prod >> qbits) - 1;
  else
    // return prod / static_cast<T>(pow(2, 8));
    return (prod >> qbits);
}

template <typename T>
void conv(Mat3D<T> &output, Mat3D<T> &input, Mat4D<T> &weight)
{
  auto padded = zeros<T>(n_in, img_height+2*conv_pad, img_width+2*conv_pad);

  for range(n, n_in)
  for range(i, img_height)
  for range(j, img_width)
    padded[n][i+conv_pad][j+conv_pad] = input[n][i][j];

  for range(n, n_out)
  for ranges(i, img_height+2*conv_pad-conv_kern+1, conv_strid)
  for ranges(j, img_width+2*conv_pad-conv_kern+1, conv_strid) {
    T acc = 0;
    for range(m, n_in)
    for range(di, conv_kern)
    for range(dj, conv_kern)
      acc += mul<T>(padded[m][i+di][j+dj], weight[n][m][di][dj]);
    output[n][i/conv_strid][j/conv_strid] = acc;
  }
}

template <typename T>
void bias(Mat3D<T> &output, Mat3D<T> &input, Mat1D<T> bias)
{
  for range(n, n_out)
  for range(i, fea_height)
  for range(j, fea_width)
    output[n][i][j] = input[n][i][j] + bias[n];
}

template <typename T>
void relu(Mat3D<T> &output, Mat3D<T> &input)
{
  for range(n, n_out)
  for range(i, fea_height)
  for range(j, fea_width)
    if (input[n][i][j] > 0)
      output[n][i][j] = input[n][i][j];
    else
      output[n][i][j] = 0;
}

template <typename T>
void pool(Mat3D<T> &output, Mat3D<T> &input)
{
  auto padded = zeros<T>(n_out, fea_height+2*pool_pad+pool_strid-1,
                                fea_width+2*pool_pad+pool_strid-1);

  for range(n, n_out)
  for range(i, fea_height)
  for range(j, fea_width)
    padded[n][i+pool_pad][j+pool_pad] = input[n][i][j];

  for range(n, n_out)
  for ranges(i, fea_height+2*pool_pad+pool_strid-pool_kern, pool_strid)
  for ranges(j, fea_width+2*pool_pad+pool_strid-pool_kern, pool_strid) {
    T tmp = std::numeric_limits<T>::min();
    for range(di, pool_kern)
    for range(dj, pool_kern)
      if (padded[n][i+di][j+dj] > tmp)
        tmp = padded[n][i+di][j+dj];
    output[n][i/pool_strid][j/pool_strid] = tmp;
  }
}

int main(void)
{
  auto input  = zeros<int16_t>(n_in,  img_height, img_width);
  auto fmap   = zeros<int16_t>(n_out, fea_height, fea_width);
  auto bmap   = zeros<int16_t>(n_out, fea_height, fea_width);
  auto amap   = zeros<int16_t>(n_out, fea_height, fea_width);
  auto pmap   = zeros<int16_t>(n_out, out_height, out_width);

  auto W = zeros<int16_t>(n_out, n_in, conv_kern, conv_kern);
  auto b = zeros<int16_t>(n_out);

  load(input, "../../data/renkon/input_renkon_top.dat");
  load(W, "../../data/renkon/weight_renkon_top.dat");
  load(b, "../../data/renkon/bias_renkon_top.dat");

  conv(fmap, input, W);
  bias(bmap, fmap, b);
  relu(amap, bmap);
  pool(pmap, amap);

#if 1
  for range(n, n_out)
    for range(i, out_height)
      for range(j, out_width)
        printf("%d\n", pmap[n][i][j]);
#else
  for range(n, n_out)
    for range(i, fea_height)
      for range(j, fea_width)
        printf("%d\n", fmap[n][i][j]);
#endif

  return 0;
}
