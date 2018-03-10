#include <algorithm>
#include <cmath>
#include <numeric>

#include "squeezedet.hpp"
#include "wrapper.hpp"
#include "arithmetic.hpp"
#include "transform.hpp"
#include "activation.hpp"

#include "kinpira.h"

#include "data/conv1.hpp"
#include "data/fire2.hpp"
#include "data/fire3.hpp"
#include "data/fire4.hpp"
#include "data/fire5.hpp"
#include "data/fire6.hpp"
#include "data/fire7.hpp"
#include "data/fire8.hpp"
#include "data/fire9.hpp"
#include "data/fire10.hpp"
#include "data/fire11.hpp"
#include "data/conv12.hpp"

static inline Layer *
conv(Map *input, Map *output, int kern, int strid, int pad, bool aux)
{
  return map_layer(input, output,
    convolution_2d(kern, strid, pad, CONV_BIAS),
    NULL,
    (aux ? activation(ACTV_RELU) : NULL),
    (aux ? pooling_2d(3, 2, 0, POOL_MAX) : NULL)
  );
}

static inline std::vector<Layer *>
fire(Map *input, std::vector<Map *>& maps, bool pool)
{
  Map *sq1x1 = maps[0];
  Map *ex1x1 = maps[1];
  Map *ex3x3 = maps[2];

  return std::vector<Layer *>{
    map_layer(input, sq1x1,
      convolution_2d(1, 1, 0, CONV_BIAS),
      NULL,
      activation(ACTV_RELU),
      NULL
    ),
    map_layer(sq1x1, ex1x1,
      convolution_2d(1, 1, 0, CONV_BIAS),
      NULL,
      activation(ACTV_RELU),
      (pool ? pooling_2d(3, 2, 0, POOL_MAX) : NULL)
    ),
    map_layer(sq1x1, ex3x3,
      convolution_2d(3, 1, 1, CONV_BIAS),
      NULL,
      activation(ACTV_RELU),
      (pool ? pooling_2d(3, 2, 0, POOL_MAX) : NULL)
    ),
  };
}

static Map * define_fire(int qbits, std::vector<Map *> &maps,
                         int s1x1, int e1x1, int e3x3, int map_w, int map_h,
                         bool pool)
{
  Map *sq1x1 = pool
             ? define_map(qbits, s1x1, 2*map_w, 2*map_h)
             : define_map(qbits, s1x1, map_w, map_h);
  Map *ex1x1 = define_map(qbits, e1x1, map_w, map_h);
  Map *ex3x3 = define_map(qbits, e3x3, map_w, map_h);

  maps = std::vector<Map *>{sq1x1, ex1x1, ex3x3};

  Map *output = (Map *)malloc(sizeof(Map));

  // concatenate ex1x1 and ex3x3
  assert(ex1x1->shape[1] == ex3x3->shape[1]);
  assert(ex1x1->shape[2] == ex3x3->shape[2]);
  output->shape[0] = ex1x1->shape[0] + ex3x3->shape[0];
  output->shape[1] = ex1x1->shape[1];
  output->shape[2] = ex1x1->shape[2];

  output->body = ex1x1->body;
  output->phys_addr = ex1x1->phys_addr;
  output->qbits = ex1x1->qbits;

  return output;
}

SqueezeDet::SqueezeDet(const std::shared_ptr<Image> &in_det,
                       const std::shared_ptr<std::pair<Image, Mask>> &out_det)
  : in_det(in_det), out_det(out_det)
{
  kinpira_init();

  image  = define_map( 24,                       3, IMG_H,   IMG_W);
  pmap1  = define_map( 24,                      64, IMG_H/4, IMG_W/4);
  fmap2  = define_fire(24, fire2_maps,  16, 64, 64, IMG_H/4, IMG_W/4,  false);
  pmap3  = define_fire(24, fire3_maps,  16, 64, 64, IMG_H/8, IMG_W/8,  true);
  fmap4  = define_fire(24, fire4_maps,  32,128,128, IMG_H/8, IMG_W/8,  false);
  pmap5  = define_fire(24, fire5_maps,  32,128,128, IMG_H/16,IMG_W/16, true);
  fmap6  = define_fire(24, fire6_maps,  48,192,192, IMG_H/16,IMG_W/16, false);
  fmap7  = define_fire(24, fire7_maps,  48,192,192, IMG_H/16,IMG_W/16, false);
  fmap8  = define_fire(24, fire8_maps,  64,256,256, IMG_H/16,IMG_W/16, false);
  fmap9  = define_fire(24, fire9_maps,  64,256,256, IMG_H/16,IMG_W/16, false);
  fmap10 = define_fire(24, fire10_maps, 96,384,384, IMG_H/16,IMG_W/16, false);
  fmap11 = define_fire(24, fire11_maps, 96,384,384, IMG_H/16,IMG_W/16, false);
  fmap12 = define_map( 24,                      72, IMG_H/16,IMG_W/16);

  // in_det->body = image->body;
  in_det->body = std::unique_ptr<s32[]>(image->body);

  conv1  = conv(image,  pmap1, 3, 2, 1, true);
  fire2  = fire(pmap1,  fire2_maps,  false);
  fire3  = fire(fmap2,  fire3_maps,  true);
  fire4  = fire(pmap3,  fire4_maps,  false);
  fire5  = fire(fmap4,  fire5_maps,  true);
  fire6  = fire(pmap5,  fire6_maps,  false);
  fire7  = fire(fmap6,  fire7_maps,  false);
  fire8  = fire(fmap7,  fire8_maps,  false);
  fire9  = fire(fmap8,  fire9_maps,  false);
  fire10 = fire(fmap9,  fire10_maps, false);
  fire11 = fire(fmap10, fire11_maps, false);
  conv12 = conv(fmap11, fmap12, 3, 1, 1, false);

  assign_map_quant( conv1,  W_conv1,  b_conv1,
    24, W_conv1_min,  W_conv1_max,  b_conv1_min,  b_conv1_max );
  assign_maps_quant(fire2,  W_fire2,  b_fire2,
    24, W_fire2_min,  W_fire2_max,  b_fire2_min,  b_fire2_max );
  assign_maps_quant(fire3,  W_fire3,  b_fire3,
    24, W_fire3_min,  W_fire3_max,  b_fire3_min,  b_fire3_max );
  assign_maps_quant(fire4,  W_fire4,  b_fire4,
    24, W_fire4_min,  W_fire4_max,  b_fire4_min,  b_fire4_max );
  assign_maps_quant(fire5,  W_fire5,  b_fire5,
    24, W_fire5_min,  W_fire5_max,  b_fire5_min,  b_fire5_max );
  assign_maps_quant(fire6,  W_fire6,  b_fire6,
    24, W_fire6_min,  W_fire6_max,  b_fire6_min,  b_fire6_max );
  assign_maps_quant(fire7,  W_fire7,  b_fire7,
    24, W_fire7_min,  W_fire7_max,  b_fire7_min,  b_fire7_max );
  assign_maps_quant(fire8,  W_fire8,  b_fire8,
    24, W_fire8_min,  W_fire8_max,  b_fire8_min,  b_fire8_max );
  assign_maps_quant(fire9,  W_fire9,  b_fire9,
    24, W_fire9_min,  W_fire9_max,  b_fire9_min,  b_fire9_max );
  assign_maps_quant(fire10, W_fire10, b_fire10,
    24, W_fire10_min, W_fire10_max, b_fire10_min, b_fire10_max);
  assign_maps_quant(fire11, W_fire11, b_fire11,
    24, W_fire11_min, W_fire11_max, b_fire11_min, b_fire11_max);
  assign_map_quant( conv12, W_conv12, b_conv12,
    24, W_conv12_min, W_conv12_max, b_conv12_min, b_conv12_max);

  init_matrix();
}

SqueezeDet::~SqueezeDet()
{
#if 0
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

  undef_maps(fire2_maps);
  undef_maps(fire3_maps);
  undef_maps(fire4_maps);
  undef_maps(fire5_maps);
  undef_maps(fire6_maps);
  undef_maps(fire7_maps);
  undef_maps(fire8_maps);
  undef_maps(fire9_maps);
  undef_maps(fire10_maps);
  undef_maps(fire11_maps);

  undef_map(image);
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
#endif

  if (thr.joinable())
    thr.join();
}

void SqueezeDet::init_matrix()
{ // {{{
  anchor_box = set_anchors();

  preds                   = zeros<float>(ANCHOR_PER_GRID*(CLASSES+1+4),
                                         OUT_H, OUT_W);

  pred_class              = zeros<float>(OUT_H, OUT_W, ANCHOR_PER_GRID*CLASSES);
  pred_class_flat         = zeros<float>(ANCHORS*CLASSES);
  pred_class_             = zeros<float>(ANCHORS, CLASSES);
  pred_class_probs        = zeros<float>(ANCHORS, CLASSES);

  pred_confidence         = zeros<float>(OUT_H, OUT_W, ANCHOR_PER_GRID);
  pred_confidence_flat    = zeros<float>(ANCHORS);
  pred_confidence_scores  = zeros<float>(ANCHORS);

  pred_box                = zeros<float>(OUT_H, OUT_W, ANCHOR_PER_GRID*4);
  pred_box_flat           = zeros<float>(ANCHORS*4);
  pred_box_delta          = zeros<float>(ANCHORS, 4);

  _probs                  = zeros<float>(ANCHORS, CLASSES);
  probs                   = zeros<float>(ANCHORS);
  classes                 = zeros<int>(ANCHORS);
} // }}}

auto SqueezeDet::merge_box_delta(const Mat2D<float>& anchor,
                                 const Mat2D<float>& delta)
{ // {{{
  auto bbox_transform = [](const Mat1D<float>& cx,
                           const Mat1D<float>& cy,
                           const Mat1D<float>& w,
                           const Mat1D<float>& h) {
    Mat2D<float> out_box = zeros<float>(4, cx.size());

    Mat1D<float> half_w = w / (float)2.0;
    Mat1D<float> half_h = h / (float)2.0;
    out_box[0] = cx - half_w;
    out_box[1] = cy - half_h;
    out_box[2] = cx + half_w;
    out_box[3] = cy + half_h;

    return out_box;
  };

  auto bbox_transform_inv = [](const Mat1D<float>& xmin,
                               const Mat1D<float>& ymin,
                               const Mat1D<float>& xmax,
                               const Mat1D<float>& ymax) {
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
  // auto delta_x = delta_t[0] / 64.0f;
  // auto delta_y = delta_t[1] / 64.0f;
  // auto delta_w = delta_t[2] / 16.0f;
  // auto delta_h = delta_t[3] / 16.0f;

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

  // auto _boxes = bbox_transform(center_x, center_y, width, height);
  Mat2D<float> _boxes;
  _boxes = bbox_transform(center_x, center_y, width, height);

  auto xmins = clip<float>(_boxes[0], 0.0, IMG_W-1.0);
  auto ymins = clip<float>(_boxes[1], 0.0, IMG_H-1.0);
  auto xmaxs = clip<float>(_boxes[2], 0.0, IMG_W-1.0);
  auto ymaxs = clip<float>(_boxes[3], 0.0, IMG_H-1.0);

  boxes = bbox_transform_inv(xmins, ymins, xmaxs, ymaxs);
} // }}}

Mat1D<float> SqueezeDet::safe_exp(const Mat1D<float>& w, float thresh)
{ // {{{
  const int len = w.size();

  Mat1D<float> out(len);
  for (int i = 0; i < len; ++i) {
    auto x = w[i];
    auto y = 0.0;

    if (x > thresh) {
      y = exp(thresh) * (x - thresh + 1.0);
    }
    else {
      y = exp(x);
    }

    out[i] = y;
  }

  return out;
} // }}}

Mat2D<float> SqueezeDet::set_anchors()
{ // {{{
  auto center_x = zeros<float>(OUT_W);
  for (int i = 0; i < OUT_W; ++i) {
    center_x[i] = static_cast<float>(i+1)/(OUT_W+1) * IMG_W;
  }

  auto center_y = zeros<float>(OUT_H);
  for (int i = 0; i < OUT_H; ++i) {
    center_y[i] = static_cast<float>(i+1)/(OUT_H+1) * IMG_H;
  }

  auto anchors = zeros<float>(OUT_H*OUT_W*ANCHOR_PER_GRID, 4);
  int idx = 0;
  for (int i = 0; i < OUT_H; ++i) {
    for (int j = 0; j < OUT_W; ++j) {
      for (int k = 0; k < ANCHOR_PER_GRID; ++k) {
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
  std::vector<int> whole(ANCHORS);
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
#if 1
    for (int i = 0; i < (int)keep.size(); ++i) {
      if (keep[i]) {
        auto mask_boxes = bbox_transform(cand_boxes[i][0], cand_boxes[i][1],
                                         cand_boxes[i][2], cand_boxes[i][3]);
        mask.emplace_back(BBox{
          .name  = class_map[c],
          .prob  = cand_probs[i],
          .left  = static_cast<int>(mask_boxes[0]),
          .top   = static_cast<int>(mask_boxes[1]),
          .right = static_cast<int>(mask_boxes[2]),
          .bot   = static_cast<int>(mask_boxes[3]),
        });
      }
    }
#else
    for (int i = 0; i < 2; ++i) {
      mask.emplace_back(BBox{
        .name  = class_map[c],
        .prob  = 0.5,
        .left  = 10,
        .top   = 10,
        .right = 100,
        .bot   = 100,
      });
    }
#endif
  }
} // }}}

void SqueezeDet::interpret(const Mat3D<float>& preds)
{ // {{{
  for (int j = 0; j < OUT_H; ++j) {
    for (int k = 0; k < OUT_W; ++k) {
      // convert to tensorflow encoding
      for (int i = 0; i < num_class_probs; ++i) {
        pred_class[j][k][i] = preds[i][j][k];
      }
      for (int i = num_class_probs; i < num_confidence_scores; ++i) {
        pred_confidence[j][k][i-num_class_probs] = preds[i][j][k];
      }
      for (int i = num_confidence_scores; i < num_box_delta; ++i) {
        pred_box[j][k][i-num_confidence_scores] = preds[i][j][k];
      }
    }
  }

  flatten(pred_class_flat, pred_class);
  reshape(pred_class_, pred_class_flat);
  for (int i = 0; i < ANCHORS; ++i) {
    softmax(pred_class_probs[i], pred_class_[i]);
  }

  flatten(pred_confidence_flat, pred_confidence);
  sigmoid(pred_confidence_scores, pred_confidence_flat);

  flatten(pred_box_flat, pred_box);
  reshape(pred_box_delta, pred_box_flat);
  merge_box_delta(anchor_box, pred_box_delta);

  for (int i = 0; i < ANCHORS; ++i) {
    for (int j = 0; j < CLASSES; ++j)
      _probs[i][j] = pred_confidence_scores[i] * pred_class_probs[i][j];

    probs[i]   = max(_probs[i]);
    classes[i] = argmax(_probs[i]);
  }
} // }}}

#include <fstream>
#include <iomanip>
#define PRINT_MAP(fmap) do { \
  std::ofstream ofs(std::string(#fmap) + ".dat"); \
  int idx = 0; \
  const int map_c = (fmap)->shape[0]; \
  const int map_h = (fmap)->shape[1]; \
  const int map_w = (fmap)->shape[2]; \
  ofs << map_c << " x " << map_h << " x " << map_w << endl; \
  ofs << std::hex; \
  for (int i = 0; i < map_c; ++i) { \
    for (int j = 0; j < map_h; ++j) { \
      for (int k = 0; k < map_w; ++k) { \
        ofs << (fmap)->body[idx++] << "\t"; \
      } \
      ofs << endl; \
    } \
    ofs << endl; \
  } \
  ofs << endl << endl; \
} while (0)

void SqueezeDet::evaluate()
{
#ifdef THREAD
thr = std::thread([&] {
#endif
  // frame = std::move(*in_det);
  frame.height = in_det->height;
  frame.width = in_det->width;
  frame.scales = in_det->scales;
  frame.src = in_det->src;
  frame.mvs = std::move(in_det->mvs);

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

#if 0
  PRINT_MAP(image );
  PRINT_MAP(pmap1 );
  PRINT_MAP(fmap2 );
  PRINT_MAP(pmap3 );
  PRINT_MAP(fmap4 );
  PRINT_MAP(pmap5 );
  PRINT_MAP(fmap6 );
  PRINT_MAP(fmap7 );
  PRINT_MAP(fmap8 );
  PRINT_MAP(fmap9 );
  PRINT_MAP(fmap10);
  PRINT_MAP(fmap11);
  PRINT_MAP(fmap12);


  PRINT_MAP(fire2_maps[0]);
  PRINT_MAP(fire2_maps[1]);
  PRINT_MAP(fire2_maps[2]);
  PRINT_MAP(fire3_maps[0]);
  PRINT_MAP(fire3_maps[1]);
  PRINT_MAP(fire3_maps[2]);
  PRINT_MAP(fire4_maps[0]);
  PRINT_MAP(fire4_maps[1]);
  PRINT_MAP(fire4_maps[2]);
  PRINT_MAP(fire5_maps[0]);
  PRINT_MAP(fire5_maps[1]);
  PRINT_MAP(fire5_maps[2]);
  exit(0);
#endif

  int idx = 0;
  const float qoffs = 1 << fmap12->qbits;
  for (int i = 0; i < fmap12->shape[0]; ++i) {
    for (int j = 0; j < fmap12->shape[1]; ++j) {
      for (int k = 0; k < fmap12->shape[2]; ++k) {
        preds[i][j][k] = fmap12->body[idx++] / qoffs;
#if 0
        std::this_thread::sleep_for(std::chrono::microseconds(1));
#endif
      }
    }
  }

  interpret(preds);
  filter();

  *out_det = std::make_pair(std::move(frame), mask);
#ifdef THREAD
});
#endif
}

void SqueezeDet::sync()
{
#ifdef THREAD
  thr.join();
#endif
}
