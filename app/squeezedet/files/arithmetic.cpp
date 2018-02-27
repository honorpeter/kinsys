#ifdef _ARITHMETIC_HPP_

#include <limits>

template <typename T>
Mat1D<T> operator+(const Mat1D<T>& x, const Mat1D<T>& y)
{
  const int len = x.size();
  auto z = zeros<T>(len);

  for (int i = 0; i < len; ++i)
    z[i] = x[i] + y[i];

  return z;
}

template <typename T>
Mat1D<T> operator-(const Mat1D<T>& x, const Mat1D<T>& y)
{
  const int len = x.size();
  auto z = zeros<T>(len);

  for (int i = 0; i < len; ++i)
    z[i] = x[i] - y[i];

  return z;
}

template <typename T>
Mat1D<T> operator*(const Mat1D<T>& x, const Mat1D<T>& y)
{
  const int len = x.size();
  auto z = zeros<T>(len);

  for (int i = 0; i < len; ++i)
    z[i] = x[i] * y[i];

  return z;
}

template <typename T>
Mat1D<T> operator/(const Mat1D<T>& x, const Mat1D<T>& y)
{
  const int len = x.size();
  auto z = zeros<T>(len);

  for (int i = 0; i < len; ++i)
    z[i] = x[i] / y[i];

  return z;
}

template <typename T>
Mat1D<T> operator+(T x, const Mat1D<T>& y)
{
  const int len = y.size();
  auto z = zeros<T>(len);

  for (int i = 0; i < len; ++i)
    z[i] = x + y[i];

  return z;
}

template <typename T>
Mat1D<T> operator+(const Mat1D<T>& x, T y)
{
  const int len = x.size();
  auto z = zeros<T>(len);

  for (int i = 0; i < len; ++i)
    z[i] = x[i] + y;

  return z;
}

template <typename T>
Mat1D<T> operator-(T x, const Mat1D<T>& y)
{
  const int len = y.size();
  auto z = zeros<T>(len);

  for (int i = 0; i < len; ++i)
    z[i] = x - y[i];

  return z;
}

template <typename T>
Mat1D<T> operator-(const Mat1D<T>& x, T y)
{
  const int len = x.size();
  auto z = zeros<T>(len);

  for (int i = 0; i < len; ++i)
    z[i] = x[i] - y;

  return z;
}

template <typename T>
Mat1D<T> operator*(T x, const Mat1D<T>& y)
{
  const int len = y.size();
  auto z = zeros<T>(len);

  for (int i = 0; i < len; ++i)
    z[i] = x * y[i];

  return z;
}

template <typename T>
Mat1D<T> operator*(const Mat1D<T>& x, T y)
{
  const int len = x.size();
  auto z = zeros<T>(len);

  for (int i = 0; i < len; ++i)
    z[i] = x[i] * y;

  return z;
}

template <typename T>
Mat1D<T> operator/(T x, const Mat1D<T>& y)
{
  const int len = y.size();
  auto z = zeros<T>(len);

  for (int i = 0; i < len; ++i)
    z[i] = x / y[i];

  return z;
}

template <typename T>
Mat1D<T> operator/(const Mat1D<T>& x, T y)
{
  const int len = x.size();
  auto z = zeros<T>(len);

  for (int i = 0; i < len; ++i)
    z[i] = x[i] / y;

  return z;
}

template <typename T>
T clip(T source, T min, T max)
{
  T target;

  if (source < min)
    target = min;
  else if (source > max)
    target = max;
  else
    target = source;

  return target;
}

template <typename T>
Mat1D<T> clip(const Mat1D<T>& source, T min, T max)
{
  const int len = source.size();
  auto target = zeros<T>(len);

  for (int i = 0; i < len; ++i) {
    const T val = source[i];
    if (val < min)
      target[i] = min;
    else if (val > max)
      target[i] = max;
    else
      target[i] = val;
  }

  return target;
}

template <typename T>
T max(const Mat1D<T>& x)
{
  const int len = x.size();

  T acc = std::numeric_limits<T>::min();
  for (int i = 0; i < len; ++i) {
    if (acc < x[i]) {
      acc = x[i];
    }
  }

  return acc;
}

template <typename T>
int argmax(const Mat1D<T>& x)
{
  const int len = x.size();

  int idx = -1;
  T acc = std::numeric_limits<T>::min();
  for (int i = 0; i < len; ++i) {
    if (acc < x[i]) {
      acc = x[i];
      idx = i;
    }
  }

  return idx;
}

template <typename T>
T min(const Mat1D<T>& x)
{
  const int len = x.size();

  T acc = std::numeric_limits<T>::max();
  for (int i = 0; i < len; ++i) {
    if (acc > x[i]) {
      acc = x[i];
    }
  }

  return acc;
}

template <typename T>
int argmin(const Mat1D<T>& x)
{
  const int len = x.size();

  int idx = -1;
  T acc = std::numeric_limits<T>::max();
  for (int i = 0; i < len; ++i) {
    if (acc > x[i]) {
      acc = x[i];
      idx = i;
    }
  }

  return idx;
}

#include "wrapper.hpp"
template <typename T>
Mat2D<T> transpose(const Mat2D<T>& x)
{
  const int len_x = x.size();
  const int len_y = x[0].size();
  auto x_t = zeros<T>(len_y, len_x);

  for (int i = 0; i < len_y; ++i)
    for (int j = 0; j < len_x; ++j)
      x_t[i][j] = x[j][i];

  return x_t;
}

#endif
