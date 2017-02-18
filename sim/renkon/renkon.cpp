#include <cstdio>
#include <cfloat>
#include <cmath>
#include <lib.hpp>

const int n_out = 32;
const int n_in  = 16;
const int isize = 12;
const int fsize = 5;
const int psize = 2;
const int osize = (isize-fsize+1)/psize;

template <typename T>
T mult(T x, T y)
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
  for range(n, n_out)
  for range(m, n_in)
  for range(i, isize-fsize+1)
  for range(j, isize-fsize+1) {
    output[n][i][j] = 0;
    for range(di, fsize)
    for range(dj, fsize)
      output[n][i][j] += mult<T>(input[m][i+di][j+dj], weight[n][m][di][dj]);
  }
}

template <typename T>
void bias(Mat3D<T> &output, Mat3D<T> &input, Mat1D<T> bias)
{
  for range(n, n_out)
    for range(i, isize-fsize+1)
      for range(j, isize-fsize+1)
        output[n][i][j] = input[n][i][j] + bias[n];
}

template <typename T>
void relu(Mat3D<T> &output, Mat3D<T> &input)
{
  for range(n, n_out)
    for range(i, isize-fsize+1)
      for range(j, isize-fsize+1)
        if (input[n][i][j] > 0)
          output[n][i][j] = input[n][i][j];
        else
          output[n][i][j] = 0;
}

template <typename T>
void pool(Mat3D<T> &output, Mat3D<T> &input)
{
  for range(n, n_out)
  for (int i = 0; i < isize-fsize+1; i+=psize)
  for (int j = 0; j < isize-fsize+1; j+=psize) {
    double tmp = -DBL_MAX;
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
  auto fmap   = zeros<int16_t>(n_out, isize-fsize+1, isize-fsize+1);
  auto bmap   = zeros<int16_t>(n_out, isize-fsize+1, isize-fsize+1);
  auto amap   = zeros<int16_t>(n_out, isize-fsize+1, isize-fsize+1);
  auto pmap   = zeros<int16_t>(n_out, osize, osize);

  auto W = zeros<int16_t>(n_out, n_in, fsize, fsize);
  auto b = zeros<int16_t>(n_out);

  load(input, "../../data/renkon/input_renkon.dat");
  load(W, "../../data/renkon/weight_renkon.dat");
  load(b, "../../data/renkon/bias_renkon.dat");

  conv<int16_t>(fmap, input, W);
  bias<int16_t>(bmap, fmap, b);
  relu<int16_t>(amap, bmap);
  pool<int16_t>(pmap, amap);

  for range(n, n_out)
    for range(i, osize)
      for range(j, osize)
        printf("%d\n", pmap[n][i][j]);

  return 0;
}
