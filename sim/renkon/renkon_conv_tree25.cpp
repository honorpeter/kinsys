#include <cstdio>
#include <cmath>
#include <lib.hpp>

const int number = 1000;
const int size   = 25;

template <typename T>
T mult(T x, T y)
{
  T prod = x * y;

  if (prod >= 0)
    return prod / static_cast<T>(pow(2, 8));
  else
    return prod / static_cast<T>(pow(2, 8)) - 1;
}

template <typename T>
T conv_tree(Mat1D<T> &images, Mat1D<T> &filters)
{
  T result = 0;

  for range(i, size)
    result += mult<T>(images[i], filters[i]);

  return result;
}

int main(void)
{
  using T = int16_t;

  auto images  = zeros<T>(number, size);
  auto filters = zeros<T>(number, size);
  auto results = zeros<T>(number);

  load(images, "../../data/renkon/input_renkon_conv_tree25.dat");
  load(filters, "../../data/renkon/filter_renkon_conv_tree25.dat");

  for range(n, number)
    results[n] = conv_tree(images[n], filters[n]);

  for range(n, number)
    printf("%d\n", results[n]);

  return 0;
}
