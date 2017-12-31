#ifdef _ACTV_HPP_

#include <cmath>
#include <limits>

void softmax(Mat1D<float>& output, Mat1D<float>& input)
{
  const int len = input.size();

  float expsum = 0.0;
  for (int i = 0; i < len; ++i)
    expsum += exp(input[i]);

  if (std::abs(expsum-0.0) < std::numeric_limits<float>::epsilon())
    throw "softmax calculation failed";

  for (int i = 0; i < len; ++i) {
    output[i] = exp(input[i]) / expsum;
    // NOTE: avoid inf / inf
    if (std::isnan(output[i]))
      output[i] = 1.0;
  }
}

void sigmoid(Mat1D<float>& output, Mat1D<float>& input)
{
  const int len = input.size();

  for (int i = 0; i < len; ++i)
    output[i] = (1.0/(1.0 + exp(-input[i])));
}

#endif
