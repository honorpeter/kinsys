#ifndef _ARITHMETIC_HPP_
#define _ARITHMETIC_HPP_

#include "matrix.hpp"

template <typename T>
Mat1D<T> operator+(Mat1D<T>& x, Mat1D<T>& y);

template <typename T>
Mat1D<T> operator-(Mat1D<T>& x, Mat1D<T>& y);

template <typename T>
Mat1D<T> operator*(Mat1D<T>& x, Mat1D<T>& y);

template <typename T>
Mat1D<T> operator/(Mat1D<T>& x, Mat1D<T>& y);

template <typename T>
Mat1D<T> operator+(T x, Mat1D<T>& y);

template <typename T>
Mat1D<T> operator+(Mat1D<T>& x, T y);

template <typename T>
Mat1D<T> operator-(T x, Mat1D<T>& y);

template <typename T>
Mat1D<T> operator-(Mat1D<T>& x, T y);

template <typename T>
Mat1D<T> operator*(T x, Mat1D<T>& y);

template <typename T>
Mat1D<T> operator*(Mat1D<T>& x, T y);

template <typename T>
Mat1D<T> operator/(T x, Mat1D<T>& y);

template <typename T>
Mat1D<T> operator/(Mat1D<T>& x, T y);

template <typename T>
T clip(T input, T min, T max);

template <typename T>
Mat1D<T> clip(Mat1D<T> input, T min, T max);

template <typename T>
T max(Mat1D<T> x);

template <typename T>
int argmax(Mat1D<T> x);

template <typename T>
T min(Mat1D<T> x);

template <typename T>
int argmin(Mat1D<T> x);

template <typename T>
Mat2D<T> transpose(Mat2D<T>& x);

#include "arithmetic.cpp"
#endif
