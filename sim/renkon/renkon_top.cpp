#include <cstdio>
#include <cfloat>
#include <cmath>
#include <limits>
#include <lib.hpp>

const int n_out = 32;
const int n_in  = 16;
const int isize = 12;
// const int n_out = 16;
// const int n_in  = 1;
// const int isize = 28;
const int fsize = 5;
// const int pad   = 0;
const int pad   = (fsize-1)/2;
const int feat  = isize+2*pad-fsize+1;
const int psize = 2;
const int osize = feat/psize;

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
  auto padded = zeros<T>(n_in, isize+2*pad, isize+2*pad);

  for range(n, n_in)
  for range(i, isize)
  for range(j, isize)
    padded[n][i+pad][j+pad] = input[n][i][j];

  for range(n, n_out)
  for range(i, feat)
  for range(j, feat) {
    output[n][i][j] = 0;
    for range(m, n_in)
    for range(di, fsize)
    for range(dj, fsize)
      output[n][i][j] += mul<T>(padded[m][i+di][j+dj], weight[n][m][di][dj]);
  }
}

template <typename T>
void bias(Mat3D<T> &output, Mat3D<T> &input, Mat1D<T> bias)
{
  for range(n, n_out)
    for range(i, feat)
      for range(j, feat)
        output[n][i][j] = input[n][i][j] + bias[n];
}

template <typename T>
void relu(Mat3D<T> &output, Mat3D<T> &input)
{
  for range(n, n_out)
    for range(i, feat)
      for range(j, feat)
        if (input[n][i][j] > 0)
          output[n][i][j] = input[n][i][j];
        else
          output[n][i][j] = 0;
}

template <typename T>
void pool(Mat3D<T> &output, Mat3D<T> &input)
{
  for range(n, n_out)
  for (int i = 0; i < feat; i+=psize)
  for (int j = 0; j < feat; j+=psize) {
    T tmp = std::numeric_limits<T>::min();
    for range(di, psize)
    for range(dj, psize)
      if (input[n][i+di][j+dj] > tmp)
        tmp = input[n][i+di][j+dj];
    output[n][i/psize][j/psize] = tmp;
  }
}

int main(void)
{
  auto input  = zeros<int16_t>(n_in, isize, isize);
  auto fmap   = zeros<int16_t>(n_out, feat, feat);
  auto bmap   = zeros<int16_t>(n_out, feat, feat);
  auto amap   = zeros<int16_t>(n_out, feat, feat);
  auto pmap   = zeros<int16_t>(n_out, osize, osize);

  auto W = zeros<int16_t>(n_out, n_in, fsize, fsize);
  auto b = zeros<int16_t>(n_out);

  load(input, "../../data/renkon/input_renkon_top.dat");
  load(W, "../../data/renkon/weight_renkon_top.dat");
  load(b, "../../data/renkon/bias_renkon_top.dat");

  conv(fmap, input, W);
  bias(bmap, fmap, b);
  relu(amap, bmap);
  pool(pmap, amap);

  for range(n, n_out)
    for range(i, osize)
      for range(j, osize)
        printf("%d\n", pmap[n][i][j]);

  return 0;
}
