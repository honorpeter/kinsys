#include <cstdio>
#include <cmath>
#include <lib.hpp>

const int n_out = 500;
const int n_in  = 800;

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
  auto input  = zeros<int16_t>(n_in);
  auto fvec   = zeros<int16_t>(n_out);
  auto bvec   = zeros<int16_t>(n_out);
  auto avec   = zeros<int16_t>(n_out);

  auto W = zeros<int16_t>(n_out, n_in);
  auto b = zeros<int16_t>(n_out);

  load(input, "../../data/gobou/input_gobou_top.dat");
  load(W, "../../data/gobou/weight_gobou_top.dat");
  load(b, "../../data/gobou/bias_gobou_top.dat");

  full<int16_t>(fvec, input, W);
  bias<int16_t>(bvec, fvec, b);
  relu<int16_t>(avec, bvec);

  for range(n, n_out)
    printf("%d\n", avec[n]);

  FILE *fp = fopen("bias.dat", "w");
  for range(i, n_out)
    fprintf(fp, "%d\n", b[i]);
  fclose(fp);

  return 0;
}
