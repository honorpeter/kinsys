#ifndef _SQUEEZEDET_HPP_
#define _SQUEEZEDET_HPP_

#include <memory>
#include <thread>
#include <vector>

#include "kinpira.h"
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
  SqueezeDet(const std::shared_ptr<Image> &in_det,
             const std::shared_ptr<std::pair<Image, Mask>> &out_det);
  ~SqueezeDet();

  void evaluate();

  void sync();

private:
  std::thread thr;

  void init_matrix();
  void interpret(Mat3D<float>& preds);
  void filter();
  auto merge_box_delta(Mat2D<float>& anchor, Mat2D<float>& delta);
  Mat1D<float> safe_exp(Mat1D<float>& w, float thresh);
  Mat2D<float> set_anchors();

  Image frame;
  Mask mask;
  std::shared_ptr<Image> in_det;
  std::shared_ptr<std::pair<Image, Mask>> out_det;

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

  std::vector<Map *> fire2_maps;
  std::vector<Map *> fire3_maps;
  std::vector<Map *> fire4_maps;
  std::vector<Map *> fire5_maps;
  std::vector<Map *> fire6_maps;
  std::vector<Map *> fire7_maps;
  std::vector<Map *> fire8_maps;
  std::vector<Map *> fire9_maps;
  std::vector<Map *> fire10_maps;
  std::vector<Map *> fire11_maps;

  Map *image;
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

  Mat2D<float> ANCHOR_BOX;
  const int ANCHOR_PER_GRID         = 9;
  const int ANCHORS                 = 78 * 24 * ANCHOR_PER_GRID;

  const std::array<std::string, 3> class_map =
    {{"car", "pedestrian", "cyclist"}};

  const int num_class_probs = 9*3;//ANCHOR_PER_GRID * CLASSES;
  const int num_confidence_scores = 9+9*3;//ANCHOR_PER_GRID + num_class_probs;
  const int num_box_delta = 9*4+9+9*3;//preds.size();

  const int out_h = 24;// preds[0].size();
  const int out_w = 78;// preds[0][0].size();

  Mat3D<float> preds;
  Mat3D<float> pred_class;
  Mat3D<float> pred_confidence;
  Mat3D<float> pred_box;
  Mat1D<float> pred_class_flat;
  Mat2D<float> pred_class_;
  Mat2D<float> pred_class_probs;
  Mat1D<float> pred_confidence_flat;
  Mat1D<float> pred_confidence_scores;
  Mat1D<float> pred_box_flat;
  Mat2D<float> pred_box_delta;
  Mat2D<float> _probs;
};

#endif
