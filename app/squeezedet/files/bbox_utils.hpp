#ifndef _BBOX_UTILS_HPP_
#define _BBOX_UTILS_HPP_

#include <array>
#include <string>
#include <memory>

#include <opencv2/opencv.hpp>
extern "C" {
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libswscale/swscale.h>
#include <libavutil/motion_vector.h>
#include <libavdevice/avdevice.h>
}

#include "kinpira.h"
#include "matrix.hpp"

struct Image {
  std::array<float, 2> scales;
  int height;
  int width;
  unsigned char *src;
  // std::unique_ptr<Mat3D<int>> mvs;
  std::unique_ptr<std::vector<AVMotionVector>> mvs;
  std::unique_ptr<s32[]> body;
  // s32 *body;
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

float iou_cost(const BBox& next_box, const BBox& prev_box);
Mat2D<float> calc_cost(const Mask& src_boxes, const Mask& dst_boxes);

Mat1D<float> bbox_transform(float cx, float cy, float w, float h);
Mat1D<float> bbox_transform_inv(float xmin, float ymin, float xmax, float ymax);
Mat1D<float> batch_iou(const Mat2D<float>& boxes, const Mat1D<float>& box);
Mat1D<bool> nms(const Mat2D<float>& boxes,
                const Mat1D<float>& probs, float thresh);

#endif
