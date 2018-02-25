#ifdef _TRANSFORM_HPP_

#include <cassert>

template <typename T>
void flatten(Mat1D<T>& output, const Mat2D<T>& input)
{
  const int size0 = input.size();
  const int size1 = input[0].size();

  assert((int)output.size() == size0 * size1);

  int idx = 0;
  for (int i = 0; i < size0; ++i) {
    for (int j = 0; j < size1; ++j) {
      output[idx] = input[i][j];
      ++idx;
    }
  }
}

template <typename T>
void flatten(Mat1D<T>& output, const Mat3D<T>& input)
{
  const int size0 = input.size();
  const int size1 = input[0].size();
  const int size2 = input[0][0].size();

  assert((int)output.size() == size0 * size1 * size2);

  int idx = 0;
  for (int i = 0; i < size0; ++i) {
    for (int j = 0; j < size1; ++j) {
      for (int k = 0; k < size2; ++k) {
        output[idx] = input[i][j][k];
        ++idx;
      }
    }
  }
}

template <typename T>
void flatten(Mat1D<T>& output, const Mat4D<T>& input)
{
  const int size0 = input.size();
  const int size1 = input[0].size();
  const int size2 = input[0][0].size();
  const int size3 = input[0][0][0].size();

  assert((int)output.size() == size0 * size1 * size2 * size3);

  int idx = 0;
  for (int i = 0; i < size0; ++i) {
    for (int j = 0; j < size1; ++j) {
      for (int k = 0; k < size2; ++k) {
        for (int l = 0; l < size3; ++l) {
          output[idx] = input[i][j][k][l];
          ++idx;
        }
      }
    }
  }
}

template <typename T>
void reshape(Mat2D<T>& output, const Mat1D<T>& input)
{
  const int size0 = output.size();
  const int size1 = output[0].size();

  assert((int)input.size() == size0 * size1);

  int idx = 0;
  for (int i = 0; i < size0; ++i) {
    for (int j = 0; j < size1; ++j) {
      output[i][j] = input[idx];
      ++idx;
    }
  }
}

template <typename T>
void reshape(Mat3D<T>& output, const Mat1D<T>& input)
{
  const int size0 = output.size();
  const int size1 = output[0].size();
  const int size2 = output[0][0].size();

  assert((int)input.size() == size0 * size1 * size2);

  int idx = 0;
  for (int i = 0; i < size0; ++i) {
    for (int j = 0; j < size1; ++j) {
      for (int k = 0; k < size2; ++k) {
        output[i][j][k] = input[idx];
        ++idx;
      }
    }
  }
}

template <typename T>
void reshape(Mat4D<T>& output, const Mat1D<T>& input)
{
  const int size0 = output.size();
  const int size1 = output[0].size();
  const int size2 = output[0][0].size();
  const int size3 = output[0][0][0].size();

  assert((int)input.size() == size0 * size1 * size2 * size3);

  int idx = 0;
  for (int i = 0; i < size0; ++i) {
    for (int j = 0; j < size1; ++j) {
      for (int k = 0; k < size2; ++k) {
        for (int l = 0; l < size3; ++l) {
          output[i][j][k][l] = input[idx];
          ++idx;
        }
      }
    }
  }
}

template <typename T>
static inline int length(const Mat1D<T>& x)
{
  return x.size();
}

template <typename T>
static inline int length(const Mat2D<T>& x)
{
  return x.size() * x[0].size();
}

template <typename T>
static inline int length(const Mat3D<T>& x)
{
  return x.size() * x[0].size() * x[0][0].size();
}

template <typename T>
static inline int length(const Mat4D<T>& x)
{
  return x.size() * x[0].size() * x[0][0].size() * x[0][0][0].size();
}

template <typename Mat>
void concat(Mat& c, const Mat& a, const Mat& b)
{
  const int n_a = a.size();
  const int n_b = b.size();

  assert((int)c.size() == n_b + n_a);

  for (int i = 0; i < n_a; ++i)
    c[i] = a[i];

  for (int i = 0; i < n_b; ++i)
    c[i+n_a] = b[i];
}

#endif
