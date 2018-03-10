#include <algorithm>
#include <numeric>

#include "bbox_utils.hpp"
#include "arithmetic.hpp"
#include "wrapper.hpp"

std::vector<float> calc_center(const BBox& box)
{
  float center_y = static_cast<float>(box.bot + box.top) / 2.0;
  float center_x = static_cast<float>(box.right + box.left) / 2.0;

  return std::vector<float>{{center_x, center_y}};
}

float iou_cost(const BBox& next_box, const BBox& prev_box)
{
  BBox cap;
  cap.left  = std::max(next_box.left, prev_box.left);
  cap.top   = std::max(next_box.top, prev_box.top);
  cap.right = std::min(next_box.right, prev_box.right);
  cap.bot   = std::min(next_box.bot, prev_box.bot);

  float area_cap;
  if (cap.left <= cap.right && cap.top <= cap.bot)
    area_cap = (cap.right - cap.left + 1) * (cap.bot - cap.top + 1);
  else
    area_cap = 0;

  int area_next = (next_box.right - next_box.left + 1)
                * (next_box.bot - next_box.top + 1);
  int area_prev = (prev_box.right - prev_box.left + 1)
                * (prev_box.bot - prev_box.top + 1);

  float area_cup = area_next + area_prev - area_cap;
  if (std::abs(area_cup-0.0) < std::numeric_limits<float>::epsilon())
    throw std::runtime_error("iou_cost failed");

  float iou = area_cap / area_cup;

  return 1.0 - iou;
}

Mat2D<float> calc_cost(const Mask& src_boxes, const Mask& dst_boxes)
{
  const int src_size = src_boxes.size();
  const int dst_size = dst_boxes.size();
  auto cost_matrix = zeros<float>(src_size, dst_size);

  for (int i = 0; i < src_size; ++i)
    for (int j = 0; j < dst_size; ++j)
      cost_matrix[i][j] = iou_cost(dst_boxes[j], src_boxes[i]);

  return cost_matrix;
}

Mat1D<float> bbox_transform(float cx, float cy, float w, float h)
{
  auto out_box = zeros<float>(4);

  out_box[0] = cx - w / 2;
  out_box[1] = cy - h / 2;
  out_box[2] = cx + w / 2;
  out_box[3] = cy + h / 2;

  return out_box;
}

Mat1D<float> bbox_transform_inv(float xmin, float ymin, float xmax, float ymax)
{
  auto out_box = zeros<float>(4);

  auto width  = xmax - xmin + 1.0;
  auto height = ymax - ymin + 1.0;

  out_box[0]  = xmin + 0.5 * width ;
  out_box[1]  = ymin + 0.5 * height;
  out_box[2]  = width;
  out_box[3]  = height;

  return out_box;
}

Mat1D<float> batch_iou(const Mat2D<float>& boxes, const Mat1D<float>& box)
{
  auto boxes_t = transpose(boxes);

  auto half_width   = (0.5f * boxes_t[2]);
  auto half_height  = (0.5f * boxes_t[3]);
  auto boxes_right  = boxes_t[0] + half_width;
  auto boxes_left   = boxes_t[0] - half_width;
  auto boxes_bottom = boxes_t[1] + half_height;
  auto boxes_top    = boxes_t[1] - half_height;
  auto box_right    = box[0] + (0.5f * box[2]);
  auto box_left     = box[0] - (0.5f * box[2]);
  auto box_bottom   = box[1] + (0.5f * box[3]);
  auto box_top      = box[1] - (0.5f * box[3]);

  auto left   = clip<float>(boxes_left,    box_left, max(boxes_left));
  auto right  = clip<float>(boxes_right,   min(boxes_right), box_right);
  auto top    = clip<float>(boxes_top,     box_top, max(boxes_top));
  auto bottom = clip<float>(boxes_bottom,  min(boxes_bottom), box_bottom);

  auto left_right = clip<float>(right-left, 0.0f,
                                std::numeric_limits<float>::max());
  auto top_bottom = clip<float>(bottom-top, 0.0f,
                                std::numeric_limits<float>::max());

  auto intersection_area  = left_right * top_bottom;
  auto base_area          = boxes_t[2] * boxes_t[3];
  auto whole_area         = base_area + box[2]*box[3];
  auto union_area         = whole_area - intersection_area;

  return intersection_area / union_area;
}

Mat1D<bool> nms(const Mat2D<float>& boxes,
                const Mat1D<float>& probs, float thresh)
{
  const int len = probs.size();

  std::vector<int> order(len);
  std::iota(order.begin(), order.end(), 0);
  std::sort(order.begin(), order.end(), [probs](int i, int j) {
    return probs[i] > probs[j];
  });

  Mat1D<bool> keep(len, true);
  for (int i = 0; i < len-1; ++i) {
    Mat2D<float> sub_boxes(boxes.begin()+order[i+1], boxes.end());
    auto ovps = batch_iou(sub_boxes, boxes[order[i]]);
    for (int j = 0; j < (int)ovps.size(); ++j) {
      if (ovps[j] > thresh) {
        try {
          keep.at(order[j+i+1]) = false;
        }
        catch (std::out_of_range& e) {
          continue;
        }
      }
    }
  }

  return keep;
}
