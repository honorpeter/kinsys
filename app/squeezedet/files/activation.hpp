#ifndef _ACTV_HPP_
#define _ACTV_HPP_

#include "matrix.hpp"

void softmax(Mat1D<float>& output, Mat1D<float>& input);

void sigmoid(Mat1D<float>& output, Mat1D<float>& input);

#include "activation.cpp"
#endif
