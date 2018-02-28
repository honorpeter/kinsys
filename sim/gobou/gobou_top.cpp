#include <cstdio>
#include <cmath>
#include <lib.hpp>

const int n_out = 128;
const int n_in  = 512;
// const int n_out = 4096;
// const int n_in  = 512 * 7 * 7;
const int qbits = 8;

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
void full(Mat1D<T> &output, Mat1D<T> &input, Mat2D<T> &weight)
{
  for range(n, n_out) {
    output[n] = 0;
    for range(m, n_in)
      output[n] += mul<T>(input[m], weight[n][m]);
  }
}

template <typename T>
void bias(Mat1D<T> &output, Mat1D<T> &input, Mat1D<T> bias)
{
  for range(n, n_out)
    output[n] = input[n] + bias[n];
}

template <typename T>
void relu(Mat1D<T> &output, Mat1D<T> &input)
{
  for range(n, n_out)
    if (input[n] > 0)
      output[n] = input[n];
    else
      output[n] = 0;
}

int main(void)
{
  using T = int16_t;

  auto input  = zeros<T>(n_in);
  auto fvec   = zeros<T>(n_out);
  auto bvec   = zeros<T>(n_out);
  auto avec   = zeros<T>(n_out);

  auto W = zeros<T>(n_out, n_in);
  auto b = zeros<T>(n_out);

  load(input, "../../data/gobou/input_gobou_top.dat");
  load(W, "../../data/gobou/weight_gobou_top.dat");
  load(b, "../../data/gobou/bias_gobou_top.dat");

  full(fvec, input, W);
  bias(bvec, fvec, b);
  relu(avec, bvec);

  for range(n, n_out)
    printf("%d\n", avec[n]);

  return 0;
}
