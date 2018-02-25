#ifndef _ARITHMETIC_HPP_
#define _ARITHMETIC_HPP_

#include "matrix.hpp"

template <typename T>
Mat1D<T> operator+(const Mat1D<T>& x, const Mat1D<T>& y);

template <typename T>
Mat1D<T> operator-(const Mat1D<T>& x, const Mat1D<T>& y);

template <typename T>
Mat1D<T> operator*(const Mat1D<T>& x, const Mat1D<T>& y);

template <typename T>
Mat1D<T> operator/(const Mat1D<T>& x, const Mat1D<T>& y);

template <typename T>
Mat1D<T> operator+(T x, const Mat1D<T>& y);

template <typename T>
Mat1D<T> operator+(const Mat1D<T>& x, T y);

template <typename T>
Mat1D<T> operator-(T x, const Mat1D<T>& y);

template <typename T>
Mat1D<T> operator-(const Mat1D<T>& x, T y);

template <typename T>
Mat1D<T> operator*(T x, const Mat1D<T>& y);

template <typename T>
Mat1D<T> operator*(const Mat1D<T>& x, T y);

template <typename T>
Mat1D<T> operator/(T x, const Mat1D<T>& y);

template <typename T>
Mat1D<T> operator/(const Mat1D<T>& x, T y);

template <typename T>
T clip(T input, T min, T max);

template <typename T>
Mat1D<T> clip(const Mat1D<T>& source, T min, T max);

template <typename T>
T max(const Mat1D<T>& x);

template <typename T>
int argmax(const Mat1D<T>& x);

template <typename T>
T min(const Mat1D<T>& x);

template <typename T>
int argmin(const Mat1D<T>& x);

template <typename T>
Mat2D<T> transpose(const Mat2D<T>& x);

#include "arithmetic.cpp"
#endif
