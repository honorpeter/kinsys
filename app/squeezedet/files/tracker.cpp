#include <unordered_map>

#include "tracker.hpp"
#include "wrapper.hpp"
#include "arithmetic.hpp"
#include "hungarian.hpp"

// TODO: mutex fifos
MVTracker::MVTracker(
  std::shared_ptr<std::deque<Image>> in_fifo,
  std::shared_ptr<std::deque<std::pair<Image, Track>>> out_fifo,
  std::shared_ptr<std::pair<Image, Mask>> out_det)
  : in_fifo(in_fifo), out_fifo(out_fifo), out_det(out_det)
{
  const int initial_size = 16;

  kalman.init(dp, mp, cp);
  kalman.transitionMatrix    = cv::Mat::eye(dp, dp, CV_32F) * 1.0;
  kalman.controlMatrix       = cv::Mat::eye(dp, cp, CV_32F) * 1.0;
  kalman.measurementMatrix   = cv::Mat::eye(mp, dp, CV_32F) * 1.0;
  kalman.processNoiseCov     = cv::Mat::eye(dp, dp, CV_32F) * processNoise;
  kalman.measurementNoiseCov = cv::Mat::eye(mp, mp, CV_32F) * measurementNoise;

  total = 0;
  count = 0;
  stateList.reserve(initial_size);
  errorCovList.reserve(initial_size);
}

MVTracker::~MVTracker()
{
}

int MVTracker::assign_id()
{
  return count++;
}

void MVTracker::associate(Mask& boxes)
{
  auto cost = calc_cost(prev_boxes, boxes);

  std::vector<int> row_idx, col_idx;
  std::tie(row_idx, col_idx) = linear_sum_assignment(cost);

  // set id
  std::unordered_map<int, int> n_id_map;
  for (int i = 0; i < (int)boxes.size(); ++i) {
    auto col = std::find(col_idx.begin(), col_idx.end(), i);
    if (col == col_idx.end()) {
      n_id_map[i] = assign_id();
    }
    else {
      auto row = row_idx.begin() + std::distance(col_idx.begin(), col);
      auto trans_cost = cost[*row][*col];

      if (trans_cost <= cost_thresh)
        n_id_map[i] = id_map[*row];
      else
        n_id_map[i] = assign_id();
    }
  }
  id_map = n_id_map;

  // get id
  for (int i = 0; i < (int)boxes.size(); ++i)
    tracks.push_back(std::make_pair(id_map[i], boxes[i]));

  prev_boxes = boxes;
}

void MVTracker::predict(Mask& boxes)
{
  // nop
}

void MVTracker::tracking(Image& frame, Mask& boxes)
{
  predict(boxes);
  associate(boxes);
}

Mat3D<int> find_inner(Mat3D<int>& mvs, BBox& box, Image& frame)
{
  int frame_rows = frame.height;
  int frame_cols = frame.width;
  int rows = mvs.size();
  int cols = mvs[0].size();
  Mat3D<int> inner_mvs;

  const std::array<int, 2> index_rate = {{frame_rows/rows, frame_cols/cols}};

  for (int y = index_rate[0]/2; y < frame_rows; y += index_rate[0]) {
    if (box.top <= y && y < box.bot) {
      Mat2D<int> inner_mvs_line;

      for (int x = index_rate[1]/2; x < frame_cols; x += index_rate[1])
        if (box.left <= x && x < box.right)
          inner_mvs_line.emplace_back(mvs[y][x]);

      inner_mvs.emplace_back(inner_mvs_line);
    }
  }

  return inner_mvs;
}

auto average_mvs(Mat3D<int>& inner_mvs, float filling_rate=1.0)
{
  const int rows = inner_mvs.size();
  const int cols = inner_mvs[0].size();

  std::array<float, 2> d_box = {{0.0, 0.0}};

  for (int i = 0; i < rows; ++i)
    for (int j = 0; j < cols; ++j)
      for (int k = 0; k < 2; ++k)
        d_box[k] += inner_mvs[i][j][k];

  for (int k = 0; k < 2; ++k) {
    d_box[k] /= static_cast<float>(rows * cols);
    d_box[k] *= (1.0f / filling_rate);
  }

  return d_box;
}

BBox move_bbox(BBox& box, std::array<float, 2>& d_box, Image& frame)
{
  int left  = box.left  + d_box[0];
  int top   = box.top   + d_box[1];
  int right = box.right + d_box[0];
  int bot   = box.bot   + d_box[1];

  auto height = frame.height;
  auto width = frame.width;

  BBox n_box;

  n_box.name  = box.name;
  n_box.prob  = box.prob;
  n_box.left  = clip<int>(left,  0, width-1);
  n_box.top   = clip<int>(top,   0, height-1);
  n_box.right = clip<int>(right, 0, width-1);
  n_box.bot   = clip<int>(bot,   0, height-1);

  return n_box;
}

void MVTracker::annotate()
{
#ifdef THREAD
thr = std::thread([&] {
#endif
  std::tie(frame, boxes) = *out_det;
  tracking(frame, boxes);

  // reset
  total = 0;
  count = 0;
  stateList.resize(boxes.size());
  errorCovList.resize(boxes.size());

  for (int i = 0; i < (int)boxes.size(); ++i) {
    total += 1;
    stateList[i] = cv::Mat(calc_center(boxes[i]));
    errorCovList[i] = cv::Mat::eye(dp, dp, CV_32F) * 1.0;
  }
#ifdef THREAD
});
#endif
}

void MVTracker::interpolate()
{
#ifdef THREAD
thr = std::thread([&] {
#endif
  frame = eat_front(in_fifo);
  auto mvs = frame.mvs;

  for (auto& box : boxes) {
    auto inner_mvs = find_inner(mvs, box, frame);
    auto d_box = average_mvs(inner_mvs);
    box = move_bbox(box, d_box, frame);
  }

  tracking(frame, boxes);
#ifdef THREAD
});
#endif
}

void MVTracker::sync()
{
#ifdef THREAD
  thr.join();
#endif
  out_fifo->push_back(std::make_pair(frame, tracks));
}
