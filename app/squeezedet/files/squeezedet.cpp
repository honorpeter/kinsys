#include <algorithm>
#include <cmath>
#include <numeric>

#include "squeezedet.hpp"
#include "wrapper.hpp"
#include "arithmetic.hpp"
#include "transform.hpp"
#include "activation.hpp"

#include "kinpira.h"

#include "data/conv1.h"
#include "data/fire2.h"
#include "data/fire3.h"
#include "data/fire4.h"
#include "data/fire5.h"
#include "data/fire6.h"
#include "data/fire7.h"
#include "data/fire8.h"
#include "data/fire9.h"
#include "data/fire10.h"
#include "data/fire11.h"
#include "data/conv12.h"

static inline Layer *
conv(Map *input, Map *output, int kern, int strid, int pad, bool pool)
{
  return map_layer(input, output,
    convolution_2d(kern, strid, pad, CONV_BIAS),
    NULL,
    activation(ACTV_RELU),
    (pool ? pooling_2d(3, 2, 1, POOL_MAX) : NULL)
  );
}

static inline std::vector<Layer *>
fire(Map *input, Map *output, Map *feature, bool pool)
{
  return std::vector<Layer *>{
    map_layer(input, output,
      convolution_2d(1, 1, 0, CONV_BIAS),
      NULL,
      activation(ACTV_RELU),
      NULL
    ),
    map_layer(input, output,
      convolution_2d(1, 1, 0, CONV_BIAS),
      NULL,
      activation(ACTV_RELU),
      (pool ? pooling_2d(3, 2, 1, POOL_MAX) : NULL)
    ),
    map_layer(input, output,
      convolution_2d(3, 1, 1, CONV_BIAS),
      NULL,
      activation(ACTV_RELU),
      (pool ? pooling_2d(3, 2, 1, POOL_MAX) : NULL)
    ),
  };
}

SqueezeDet::SqueezeDet(std::shared_ptr<Image> input,
                       std::shared_ptr<std::pair<Image, Mask>> output)
  : input(input), output(output)
{
  kinpira_init();

  pmap1  = define_map(64,  312, 96);
  fmap2  = define_map(128, 312, 96);
  pmap3  = define_map(128, 156, 48);
  fmap4  = define_map(256, 156, 48);
  pmap5  = define_map(256, 78,  24);
  fmap6  = define_map(384, 78,  24);
  fmap7  = define_map(384, 78,  24);
  fmap8  = define_map(512, 78,  24);
  fmap9  = define_map(512, 78,  24);
  fmap10 = define_map(768, 78,  24);
  fmap11 = define_map(768, 78,  24);
  fmap12 = define_map(72,  78,  24);

  // set_input(input, image_ptr);

  const int conv_k3_s2_pSAME = 0;
  const int pool_k3_s2_pSAME = 0;
  const int conv_k3_s1_pSAME = 0;
  conv1  = conv(image_ptr, pmap1, 3, 2, 1, true);
  fire2  = fire(pmap1,  fmap2,  false);
  fire3  = fire(fmap2,  pmap3,  true);
  fire4  = fire(pmap3,  fmap4,  false);
  fire5  = fire(fmap4,  pmap5,  true);
  fire6  = fire(pmap5,  fmap6,  false);
  fire7  = fire(fmap6,  fmap7,  false);
  fire8  = fire(fmap7,  fmap8,  false);
  fire9  = fire(fmap8,  fmap9,  false);
  fire10 = fire(fmap9,  fmap10, false);
  fire11 = fire(fmap10, fmap11, false);
  conv12 = conv(fmap11, fmap12, 3, 1, 1, false);

  // set_output(fmap12, output);

  assign_map_quant(conv1,   W_conv1,  b_conv1,  W_conv1_min,  W_conv1_max,  b_conv1_min,  b_conv1_max );
  assign_maps_quant(fire2,  W_fire2,  b_fire2,  W_fire2_min,  W_fire2_max,  b_fire2_min,  b_fire2_max );
  assign_maps_quant(fire3,  W_fire3,  b_fire3,  W_fire3_min,  W_fire3_max,  b_fire3_min,  b_fire3_max );
  assign_maps_quant(fire4,  W_fire4,  b_fire4,  W_fire4_min,  W_fire4_max,  b_fire4_min,  b_fire4_max );
  assign_maps_quant(fire5,  W_fire5,  b_fire5,  W_fire5_min,  W_fire5_max,  b_fire5_min,  b_fire5_max );
  assign_maps_quant(fire6,  W_fire6,  b_fire6,  W_fire6_min,  W_fire6_max,  b_fire6_min,  b_fire6_max );
  assign_maps_quant(fire7,  W_fire7,  b_fire7,  W_fire7_min,  W_fire7_max,  b_fire7_min,  b_fire7_max );
  assign_maps_quant(fire8,  W_fire8,  b_fire8,  W_fire8_min,  W_fire8_max,  b_fire8_min,  b_fire8_max );
  assign_maps_quant(fire9,  W_fire9,  b_fire9,  W_fire9_min,  W_fire9_max,  b_fire9_min,  b_fire9_max );
  assign_maps_quant(fire10, W_fire10, b_fire10, W_fire10_min, W_fire10_max, b_fire10_min, b_fire10_max);
  assign_maps_quant(fire11, W_fire11, b_fire11, W_fire11_min, W_fire11_max, b_fire11_min, b_fire11_max);
  assign_map_quant(conv12,  W_conv12, b_conv12, W_fire12_min, W_fire12_max, b_fire12_min, b_fire12_max);

  ANCHOR_BOX = set_anchors();
}

SqueezeDet::~SqueezeDet()
{
  undef_layer(conv1);
  undef_layers(fire2);
  undef_layers(fire3);
  undef_layers(fire4);
  undef_layers(fire5);
  undef_layers(fire6);
  undef_layers(fire7);
  undef_layers(fire8);
  undef_layers(fire9);
  undef_layers(fire10);
  undef_layers(fire11);
  undef_layer(conv12);

  undef_map(image_ptr);
  undef_map(pmap1);
  undef_map(fmap2);
  undef_map(pmap3);
  undef_map(fmap4);
  undef_map(pmap5);
  undef_map(fmap6);
  undef_map(fmap7);
  undef_map(fmap8);
  undef_map(fmap9);
  undef_map(fmap10);
  undef_map(fmap11);
  undef_map(fmap12);

  kinpira_exit();
}

auto SqueezeDet::merge_box_delta(Mat2D<float>& anchor, Mat2D<float>& delta)
{ // {{{
  auto bbox_transform =
  [](Mat1D<float> cx, Mat1D<float> cy, Mat1D<float> w, Mat1D<float> h) {
    Mat2D<float> out_box = zeros<float>(4, cx.size());

    Mat1D<float> half_w = w / (float)2.0;
    Mat1D<float> half_h = h / (float)2.0;
    out_box[0] = cx - half_w;
    out_box[1] = cy - half_h;
    out_box[2] = cx + half_w;
    out_box[3] = cy + half_h;

    return out_box;
  };

  auto bbox_transform_inv =
  [](Mat1D<float> xmin, Mat1D<float> ymin, Mat1D<float> xmax, Mat1D<float> ymax) {
    Mat2D<float> out_box = zeros<float>(4, xmin.size());

    Mat1D<float> width  = xmax - xmin;
    width = width + static_cast<float>(1.0);

    Mat1D<float> height = ymax - ymin;
    height = height + static_cast<float>(1.0);

    Mat1D<float> half_w = static_cast<float>(0.5) * width;
    Mat1D<float> half_h = static_cast<float>(0.5) * height;
    out_box[0]  = xmin + half_w;
    out_box[1]  = ymin + half_h;
    out_box[2]  = width;
    out_box[3]  = height;

    return transpose(out_box);
  };

  auto delta_t = transpose(delta);
  auto delta_x = delta_t[0];
  auto delta_y = delta_t[1];
  auto delta_w = delta_t[2];
  auto delta_h = delta_t[3];

  auto anchor_t = transpose(anchor);
  auto anchor_x = anchor_t[0];
  auto anchor_y = anchor_t[1];
  auto anchor_w = anchor_t[2];
  auto anchor_h = anchor_t[3];

  const float EXP_THRESH = 1.0;
  auto center_x = delta_x * anchor_w;
  center_x = anchor_x + center_x;
  auto center_y = delta_y * anchor_h;
  center_y = anchor_y + center_y;

  auto width = safe_exp(delta_w, EXP_THRESH);
  width = anchor_w * width;

  auto height = safe_exp(delta_h, EXP_THRESH);
  height = anchor_h * height;

  auto _boxes = bbox_transform(center_x, center_y, width, height);

  auto xmins = clip<float>(_boxes[0], 0.0, IMAGE_WIDTH-1.0);
  auto ymins = clip<float>(_boxes[1], 0.0, IMAGE_HEIGHT-1.0);
  auto xmaxs = clip<float>(_boxes[2], 0.0, IMAGE_WIDTH-1.0);
  auto ymaxs = clip<float>(_boxes[3], 0.0, IMAGE_HEIGHT-1.0);

  boxes = bbox_transform_inv(xmins, ymins, xmaxs, ymaxs);
} // }}}

Mat1D<float> SqueezeDet::safe_exp(Mat1D<float>& w, float thresh)
{ // {{{
  const int len = w.size();

  Mat1D<float> out(len);
  for (int i = 0; i < len; ++i) {
    auto x = w[i];
    auto y = 0.0;

    if (x > thresh)
      y = exp(thresh) * (x - thresh + 1.0);
    else
      y = exp(x);

    out[i] = y;
  }

  return out;
} // }}}

Mat2D<float> SqueezeDet::set_anchors()
{ // {{{
  const int H = 24, W = 78, B = 9;

  const float anchor_shapes[B][2] = {
    {  36.,  37.}, { 366., 174.}, { 115.,  59.},
    { 162.,  87.}, {  38.,  90.}, { 258., 173.},
    { 224., 108.}, {  78., 170.}, {  72.,  43.}
  };

  auto center_x = zeros<float>(W);
  for (int i = 0; i < W; ++i) {
    center_x[i] = static_cast<float>(i+1)/(W+1) * IMAGE_WIDTH;
  }

  auto center_y = zeros<float>(H);
  for (int i = 0; i < H; ++i) {
    center_y[i] = static_cast<float>(i+1)/(H+1) * IMAGE_HEIGHT;
  }

  auto anchors = zeros<float>(H*W*B, 4);
  int idx = 0;
  for (int i = 0; i < H; ++i) {
    for (int j = 0; j < W; ++j) {
      for (int k = 0; k < B; ++k) {
        anchors[idx][0] = center_x[j];
        anchors[idx][1] = center_y[i];
        anchors[idx][2] = anchor_shapes[k][0];
        anchors[idx][3] = anchor_shapes[k][1];
        ++idx;
      }
    }
  }

  return anchors;
} // }}}

void SqueezeDet::filter()
{ // {{{
  std::vector<int> whole(probs.size());
  std::iota(whole.begin(), whole.end(), 0);
  std::vector<int> order;

  if (0 < TOP_N_DETECTION && TOP_N_DETECTION < (int)probs.size()) {
    std::sort(whole.begin(), whole.end(), [&](int i, int j) {
      return probs[i] > probs[j];
    });
    order.assign(whole.begin(), whole.begin()+TOP_N_DETECTION);
  }
  else {
    std::copy_if(whole.begin(), whole.end(), order.begin(), [&](int i) {
      return probs[i] > PROB_THRESH;
    });
  }

  Mat2D<float>  new_boxes;
  Mat1D<float>  new_probs;
  Mat1D<int>    new_class;
  for (int i : order) {
    new_boxes.emplace_back(boxes[i]);
    new_probs.emplace_back(probs[i]);
    new_class.emplace_back(classes[i]);
  }

  mask.clear();
  for (int c = 0; c < CLASSES; ++c) {
    Mat1D<float>  cand_probs;
    Mat2D<float>  cand_boxes;
    for (int i = 0; i < (int)new_class.size(); ++i) {
      if (new_class[i] == c) {
        cand_boxes.emplace_back(new_boxes[i]);
        cand_probs.emplace_back(new_probs[i]);
      }
    }

    auto keep = nms(cand_boxes, cand_probs, NMS_THRESH);
    for (int i = 0; i < (int)keep.size(); ++i) {
      if (keep[i]) {
        // TODO: (x, y, w, h) to (l, t, r, b)
        mask.emplace_back(BBox{
          .name  = class_map[c],
          .prob  = cand_probs[i],
          .left  = static_cast<int>(cand_boxes[i][0]),
          .top   = static_cast<int>(cand_boxes[i][1]),
          .right = static_cast<int>(cand_boxes[i][2]),
          .bot   = static_cast<int>(cand_boxes[i][3]),
        });
      }
    }
  }
} // }}}

void SqueezeDet::interpret(Mat3D<float>& preds)
{ // {{{
  const int num_class_probs = ANCHOR_PER_GRID * CLASSES;
  const int num_confidence_scores = ANCHOR_PER_GRID + num_class_probs;
  const int num_box_delta = preds.size();

  const int out_h = preds[0].size();
  const int out_w = preds[0][0].size();

  auto pred_class = zeros<float>(out_h, out_w, ANCHOR_PER_GRID * CLASSES);
  auto pred_confidence = zeros<float>(out_h, out_w, ANCHOR_PER_GRID);
  auto pred_box = zeros<float>(out_h, out_w,
                               num_box_delta-num_confidence_scores);
  for (int j = 0; j < out_h; ++j) {
    for (int k = 0; k < out_w; ++k) {
      // convert to tensorflow encoding
      for (int i = 0; i < num_class_probs; ++i)
        pred_class[j][k][i] = preds[i][j][k];

      for (int i = num_class_probs; i < num_confidence_scores; ++i)
        pred_confidence[j][k][i-num_class_probs] = preds[i][j][k];

      for (int i = num_confidence_scores; i < num_box_delta; ++i)
        pred_box[j][k][i-num_confidence_scores] = preds[i][j][k];
    }
  }

  auto pred_class_flat = zeros<float>(ANCHORS*CLASSES);
  auto pred_class_ = zeros<float>(ANCHORS, CLASSES);
  auto pred_class_probs = zeros<float>(ANCHORS, CLASSES);
  flatten(pred_class_flat, pred_class);
  reshape(pred_class_, pred_class_flat);
  for (int i = 0; i < ANCHORS; ++i)
    softmax(pred_class_probs[i], pred_class_[i]);

  auto pred_confidence_flat = zeros<float>(ANCHORS);
  auto pred_confidence_scores = zeros<float>(ANCHORS);
  flatten(pred_confidence_flat, pred_confidence);
  sigmoid(pred_confidence_scores, pred_confidence_flat);

  auto pred_box_flat = zeros<float>(ANCHORS*4);
  auto pred_box_delta = zeros<float>(ANCHORS, 4);
  flatten(pred_box_flat, pred_box);
  reshape(pred_box_delta, pred_box_flat);
  merge_box_delta(ANCHOR_BOX, pred_box_delta);

  Mat2D<float> _probs = zeros<float>(ANCHORS, CLASSES);
  for (int i = 0; i < ANCHORS; ++i)
    // scalar * vector
    _probs[i] = pred_confidence_scores[i] * pred_class_probs[i];

  probs = zeros<float>(ANCHORS);
  classes = zeros<int>(ANCHORS);
  for (int i = 0; i < ANCHORS; ++i) {
    probs[i] = max(_probs[i]);
    classes[i] = argmax(_probs[i]);
  }

  *output = std::make_pair(frame, mask);
} // }}}

void SqueezeDet::evaluate()
{
  frame = *input;

  exec_core(conv1);
  exec_cores(fire2);
  exec_cores(fire3);
  exec_cores(fire4);
  exec_cores(fire5);
  exec_cores(fire6);
  exec_cores(fire7);
  exec_cores(fire8);
  exec_cores(fire9);
  exec_cores(fire10);
  exec_cores(fire11);
  exec_core(conv12);

  Mat3D<float> preds;
  int idx = 0;
  for (int i = 0; i < fmap12->shape[0]; ++i)
    for (int j = 0; j < fmap12->shape[1]; ++j)
      for (int k = 0; k < fmap12->shape[2]; ++k)
        preds[i][j][k] = static_cast<float>(fmap12->body[idx++]);

  interpret(preds);
  filter();
}

void SqueezeDet::sync()
{
}
