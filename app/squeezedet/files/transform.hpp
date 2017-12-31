#ifndef _TRANSFORM_HPP_
#define _TRANSFORM_HPP_

#include "matrix.hpp"

template <typename T>
void flatten(Mat1D<T>& output, Mat2D<T>& input);

template <typename T>
void flatten(Mat1D<T>& output, Mat3D<T>& input);

template <typename T>
void flatten(Mat1D<T>& output, Mat4D<T>& input);

template <typename T>
void reshape(Mat2D<T>& output, Mat1D<T>& input);

template <typename T>
void reshape(Mat3D<T>& output, Mat1D<T>& input);

template <typename T>
void reshape(Mat4D<T>& output, Mat1D<T>& input);

template <typename Mat>
void concat(Mat& c, Mat& a, Mat& b);

#include "transform.cpp"
#endif
