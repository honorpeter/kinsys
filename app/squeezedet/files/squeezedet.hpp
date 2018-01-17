#ifndef _SQUEEZEDET_HPP_
#define _SQUEEZEDET_HPP_

#include <memory>
#include <vector>

#include "types.h"
#include "bbox_utils.hpp"
#include "matrix.hpp"

struct BBoxMask
{
  Mat2D<float> det_boxes;
  Mat1D<float> det_probs;
  Mat1D<int> det_class;
  std::array<float, 2> scales;
};

class SqueezeDet
{
public:
  SqueezeDet(std::shared_ptr<Image> input,
             std::shared_ptr<std::pair<Image, Mask>> output);
  ~SqueezeDet();

  void evaluate();

  void sync();

private:
  void interpret(Mat3D<float>& preds);
  void filter();
  auto merge_box_delta(Mat2D<float>& anchor, Mat2D<float>& delta);
  Mat1D<float> safe_exp(Mat1D<float>& w, float thresh);
  Mat2D<float> set_anchors();

  Image frame;
  Mask mask;
  std::shared_ptr<Image> input;
  std::shared_ptr<std::pair<Image, Mask>> output;

  Mat2D<float> boxes;
  Mat1D<float> probs;
  Mat1D<int> classes;

  Layer *              conv1;
  std::vector<Layer *> fire2;
  std::vector<Layer *> fire3;
  std::vector<Layer *> fire4;
  std::vector<Layer *> fire5;
  std::vector<Layer *> fire6;
  std::vector<Layer *> fire7;
  std::vector<Layer *> fire8;
  std::vector<Layer *> fire9;
  std::vector<Layer *> fire10;
  std::vector<Layer *> fire11;
  Layer *              conv12;

// #define _PARAM(name) \
// u8 * W_##name; float W_##name##_min; float W_##name##_max; \
// u8 * b_##name; float b_##name##_min; float b_##name##_max;
//   _PARAM(conv1);
//   _PARAM(fire2);
//   _PARAM(fire3);
//   _PARAM(fire4);
//   _PARAM(fire5);
//   _PARAM(fire6);
//   _PARAM(fire7);
//   _PARAM(fire8);
//   _PARAM(fire9);
//   _PARAM(fire10);
//   _PARAM(fire11);
//   _PARAM(conv12);
// #undef _PARAM

  Map *image_ptr;
  Map *pmap1;
  Map *fmap2;
  Map *pmap3;
  Map *fmap4;
  Map *pmap5;
  Map *fmap6;
  Map *fmap7;
  Map *fmap8;
  Map *fmap9;
  Map *fmap10;
  Map *fmap11;
  Map *fmap12;

  const int CLASSES                 = 3;
  const int IMAGE_WIDTH             = 1248;
  const int IMAGE_HEIGHT            = 384;

  const float NMS_THRESH            = 0.4;
  const float PROB_THRESH           = 0.005;
  const int TOP_N_DETECTION         = 64;

  const bool EXCLUDE_HARD_EXAMPLES  = false;

  Mat2D<float> ANCHOR_BOX;
  const int ANCHOR_PER_GRID         = 9;
  const int ANCHORS                 = 78 * 24 * ANCHOR_PER_GRID;

  const std::array<std::string, 3> class_map =
    {{"car", "pedestrian", "cyclist"}};
};

#endif
