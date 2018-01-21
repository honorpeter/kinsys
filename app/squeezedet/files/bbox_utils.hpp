#ifndef _BBOX_UTILS_HPP_
#define _BBOX_UTILS_HPP_

#include <array>
#include <string>

#include <opencv2/opencv.hpp>

#include "kinpira.h"
#include "matrix.hpp"

struct Image {
  float scales[2];
  Mat3D<int> mvs;
  int height;
  int width;
  unsigned char *src;
  s16 *body;
};

struct BBox {
  std::string name;
  float prob;
  int left;
  int top;
  int right;
  int bot;
};

using Mask = std::vector<BBox>;
using Track = std::vector<std::pair<int, BBox>>;

std::vector<float> calc_center(BBox& box);
float iou_cost(BBox& box);
Mat2D<float> calc_cost(Mask& src_boxes, Mask& dst_boxes);

Mat1D<float> bbox_transform(float cx, float cy, float w, float h);
Mat1D<float> bbox_transform_inv(float xmin, float ymin, float xmax, float ymax);
Mat1D<float> batch_iou(Mat2D<float> boxes, Mat1D<float> box);
Mat1D<bool> nms(Mat2D<float> boxes, Mat1D<float> probs, float thresh);

#endif
