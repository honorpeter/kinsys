#include <cstdio>
#include <cfloat>
#include <cmath>
#include <cassert>
#include <limits>
#include <lib.hpp>

const int qbits     = 8;

const int isize     = 28;
const int fsize     = 5;
const int psize     = 2;

const int pm0size   = (isize-fsize+1)/psize;
const int pm1size   = (pm0size-fsize+1)/psize;

const int n_im      = 1;
const int n_c0      = 16;
const int n_c1      = 32;
const int n_c1_flat = n_c1 * pm1size * pm1size;
const int n_f2      = 128;
const int n_f3      = 10;

template <typename T>
T mul(T x, T y)
{
  int64_t prod = (int64_t)x * (int64_t)y;

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
  const int n_out = output.size();
  const int n_in  = input.size();
  const int isize = input[0].size();
  const int osize = output[0].size();

  assert(osize == isize-fsize+1);

  for range(n, n_out)
  for range(i, isize-fsize+1)
  for range(j, isize-fsize+1) {
    output[n][i][j] = 0;
    for range(m, n_in)
    for range(di, fsize)
    for range(dj, fsize)
      output[n][i][j] += mul<T>(input[m][i+di][j+dj], weight[n][m][di][dj]);
  }
}

template <typename T>
void bias(Mat3D<T> &output, Mat3D<T> &input, Mat1D<T> bias)
{
  const int n_out = output.size();
  const int isize = input[0].size();

  for range(n, n_out)
    for range(i, isize)
      for range(j, isize)
        output[n][i][j] = input[n][i][j] + bias[n];
}

template <typename T>
void relu(Mat3D<T> &output, Mat3D<T> &input)
{
  const int n_out = output.size();
  const int isize = input[0].size();

  for range(n, n_out)
    for range(i, isize)
      for range(j, isize)
        if (input[n][i][j] > 0)
          output[n][i][j] = input[n][i][j];
        else
          output[n][i][j] = 0;
}

template <typename T>
void pool(Mat3D<T> &output, Mat3D<T> &input)
{
  const int n_out = output.size();
  const int isize = input[0].size();

  for range(n, n_out)
  for (int i = 0; i < isize; i+=psize)
  for (int j = 0; j < isize; j+=psize) {
    T tmp = std::numeric_limits<T>::min();
    for range(di, psize)
    for range(dj, psize)
      if (input[n][i+di][j+dj] > tmp)
        tmp = input[n][i+di][j+dj];
    output[n][i/psize][j/psize] = tmp;
  }
}

template <typename T>
void full(Mat1D<T> &output, Mat1D<T> &input, Mat2D<T> &weight)
{
  const int n_out = output.size();
  const int n_in  = input.size();

  for range(n, n_out) {
    output[n] = 0;
    for range(m, n_in)
      output[n] += mul<T>(input[m], weight[n][m]);
  }
}

template <typename T>
void bias(Mat1D<T> &output, Mat1D<T> &input, Mat1D<T> bias)
{
  const int n_out = output.size();
  const int n_in  = input.size();

  assert(n_out == n_in);

  for range(n, n_out)
    output[n] = input[n] + bias[n];
}

template <typename T>
void relu(Mat1D<T> &output, Mat1D<T> &input)
{
  const int n_out = output.size();
  const int n_in  = input.size();

  assert(n_out == n_in);

  for range(n, n_out)
    if (input[n] > 0)
      output[n] = input[n];
    else
      output[n] = 0;
}

int main(int argc, char **argv)
{
  using T = int32_t;

  auto input  = zeros<T>(n_im, isize, isize);

  std::string input_label = argv[1];
  std::string input_name  = argv[2];
  load(input, "../../data/common/"+input_label+"_img"+input_name+".dat");

  auto fmap0  = zeros<T>(n_c0, isize-fsize+1, isize-fsize+1);
  auto bmap0  = zeros<T>(n_c0, isize-fsize+1, isize-fsize+1);
  auto amap0  = zeros<T>(n_c0, isize-fsize+1, isize-fsize+1);
  auto pmap0  = zeros<T>(n_c0, pm0size, pm0size);

  auto W_conv0 = zeros<T>(n_c0, n_im, fsize, fsize);
  auto b_conv0 = zeros<T>(n_c0);

  load(W_conv0, "../../data/common/W_conv0.dat");
  load(b_conv0, "../../data/common/b_conv0.dat");

  conv(fmap0, input, W_conv0);
  bias(bmap0, fmap0, b_conv0);
  relu(amap0, bmap0);
  pool(pmap0, amap0);

  save(pmap0, "../../data/common/conv0_tru.dat");

  auto fmap1  = zeros<T>(n_c1, pm0size-fsize+1, pm0size-fsize+1);
  auto bmap1  = zeros<T>(n_c1, pm0size-fsize+1, pm0size-fsize+1);
  auto amap1  = zeros<T>(n_c1, pm0size-fsize+1, pm0size-fsize+1);
  auto pmap1  = zeros<T>(n_c1, pm1size, pm1size);

  auto W_conv1 = zeros<T>(n_c1, n_c0, fsize, fsize);
  auto b_conv1 = zeros<T>(n_c1);

  load(W_conv1, "../../data/common/W_conv1.dat");
  load(b_conv1, "../../data/common/b_conv1.dat");

  conv(fmap1, pmap0, W_conv1);
  bias(bmap1, fmap1, b_conv1);
  relu(amap1, bmap1);
  pool(pmap1, amap1);

  save(pmap1, "../../data/common/conv1_tru.dat");

  auto pmap1_flat  = zeros<T>(n_c1_flat);
  load(pmap1_flat, "../../data/common/conv1_tru.dat");

  auto fvec2  = zeros<T>(n_f2);
  auto bvec2  = zeros<T>(n_f2);
  auto avec2  = zeros<T>(n_f2);

  auto W_full2 = zeros<T>(n_f2, n_c1_flat);
  auto b_full2 = zeros<T>(n_f2);

  load(W_full2, "../../data/common/W_full2.dat");
  load(b_full2, "../../data/common/b_full2.dat");

  full(fvec2, pmap1_flat, W_full2);
  bias(bvec2, fvec2, b_full2);
  relu(avec2, bvec2);

  save(avec2, "../../data/common/full2_tru.dat");

  auto fvec3  = zeros<T>(n_f3);
  auto bvec3  = zeros<T>(n_f3);
  auto avec3  = zeros<T>(n_f3);

  auto W_full3 = zeros<T>(n_f3, n_f2);
  auto b_full3 = zeros<T>(n_f3);

  load(W_full3, "../../data/common/W_full3.dat");
  load(b_full3, "../../data/common/b_full3.dat");

  full(fvec3, avec2, W_full3);
  bias(bvec3, fvec3, b_full3);
  relu(avec3, bvec3);

  save(avec3, "../../data/common/full3_tru.dat");

  return 0;
}
