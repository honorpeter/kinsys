#include <unordered_map>

#include "tracker.hpp"
#include "wrapper.hpp"
#include "arithmetic.hpp"
#include "hungarian.hpp"

MVTracker::MVTracker(
  const std::shared_ptr<std::deque<std::unique_ptr<Image>>>& in_fifo,
  const std::shared_ptr<std::deque<
    std::pair<std::unique_ptr<Image>, std::unique_ptr<Track>>>>& out_fifo,
  const std::shared_ptr<std::pair<Image, Mask>> &out_det)
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
  if (thr.joinable())
    thr.join();
}

int MVTracker::assign_id()
{
  return count++;
}

void MVTracker::associate(const Mask& boxes)
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

  prev_boxes = boxes;
}

void MVTracker::predict(const Mask& boxes)
{
  // nop
}

void MVTracker::tracking(const Mask& boxes)
{
#if 0
  predict(boxes);
  associate(boxes);

  // get id
  tracks.clear();
  for (int i = 0; i < (int)boxes.size(); ++i)
    tracks.emplace_back(id_map[i], boxes[i]);
#else
  tracks.clear();
  for (int i = 0; i < (int)boxes.size(); ++i)
    tracks.emplace_back(0, boxes[i]);
#endif
}

std::array<float, 2> MVTracker::average_inner(
  const std::unique_ptr<std::vector<AVMotionVector>>& mvs,
  const BBox& box,
  const std::unique_ptr<Image>& frame,
  const float filling_rate)
{
  std::array<float, 2> d_box = {{0.0, 0.0}};
  if (mvs->size() == 0)
    return d_box;

  int box_size = 0;
  for (const AVMotionVector& mv : *mvs) {
    const int y = std::max(0, std::min((int)mv.dst_y, frame->height - 1));
    const int x = std::max(0, std::min((int)mv.dst_x, frame->width - 1));

    if ((box.top <= y && y < box.bot) && (box.left <= x && x < box.right)) {
      const int mvdx = mv.dst_x - mv.src_x;
      const int mvdy = mv.dst_y - mv.src_y;

      d_box[0] += mvdx;
      d_box[1] += mvdy;

      ++box_size;
    }
  }

  for (int k = 0; k < 2; ++k) {
    d_box[k] /= static_cast<float>(box_size);
    d_box[k] *= (1.0f / filling_rate);
  }

  return d_box;
}

// void MVTracker::find_inner(Mat3D<int>& inner_mvs,
Mat3D<int> MVTracker::find_inner(
                           const std::unique_ptr<Mat3D<int>>& mvs,
                           const BBox& box,
                           const std::unique_ptr<Image>& frame)
{
  const int frame_rows = frame->height;
  const int frame_cols = frame->width;
  const int rows = mvs->size();
  const int cols = mvs->at(0).size();

  const std::array<int, 2> index_rate = {{frame_rows/rows, frame_cols/cols}};

  Mat3D<int> inner_mvs(512);
  // inner_mvs.clear();
  if (box.right - box.left <= 0 || box.bot - box.top <= 0)
    return inner_mvs;

  for (int y = index_rate[0]/2; y < frame_rows; y += index_rate[0]) {
    if (box.top <= y && y < box.bot) {
      Mat2D<int> inner_mvs_line(512);
      // inner_mvs_line.clear();
      for (int x = index_rate[1]/2; x < frame_cols; x += index_rate[1])
        if (box.left <= x && x < box.right)
        {
          try {
            Mat1D<int> inner_mv;
            inner_mv = mvs->at(y).at(x);
            inner_mvs_line.emplace_back(inner_mv);
          }
          catch (std::exception& e) {
            cout << e.what() << endl;
            cout << inner_mvs.size() << ", " << inner_mvs.capacity() << endl;
            cout << inner_mvs_line.size() << ", " << inner_mvs_line.capacity() << endl;
            exit(1);
          }
        }
      inner_mvs.emplace_back(inner_mvs_line);
    }
  }

  return inner_mvs;
}

// void MVTracker::average_mvs(std::array<float, 2>& d_box,
std::array<float, 2> MVTracker::average_mvs(
                                            const Mat3D<int>& inner_mvs,
                                            float filling_rate)
{
  std::array<float, 2> d_box = {{0.0, 0.0}};
  // d_box.fill(0.0);
  if (inner_mvs.size() == 0)
    return d_box;

  const int rows = inner_mvs.size();
  const int cols = inner_mvs[0].size();

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

void MVTracker::move_bbox(BBox& box,
                          const std::array<float, 2>& d_box,
                          const std::unique_ptr<Image>& frame)
{
  int left  = box.left  + d_box[0];
  int top   = box.top   + d_box[1];
  int right = box.right + d_box[0];
  int bot   = box.bot   + d_box[1];

  auto height = frame->height;
  auto width = frame->width;

  box.name  = box.name;
  box.prob  = box.prob;
  box.left  = clip<int>(left,  0, width-1);
  box.top   = clip<int>(top,   0, height-1);
  box.right = clip<int>(right, 0, width-1);
  box.bot   = clip<int>(bot,   0, height-1);
}

void MVTracker::annotate()
{
#ifdef THREAD
thr = std::thread([&] {
#endif
  Image frame;
  std::tie(frame, boxes) = std::move(*out_det);
  tracking(boxes);

#if 0
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
#endif

  std::unique_ptr<Image> hoge = std::make_unique<Image>(std::move(frame));
  std::unique_ptr<Track> what = std::make_unique<Track>(tracks);
  auto fuga = std::make_pair(std::move(hoge), std::move(what));
  push_back(out_fifo, fuga);
#ifdef THREAD
});
#endif
}

void MVTracker::interpolate()
{
#ifdef THREAD
thr = std::thread([&] {
#endif
  auto frame = pop_front(in_fifo);

  auto mvs = std::move(frame->mvs);
  for (auto& box : boxes) {
    // find_inner(inner_mvs, mvs, box, frame);
    // average_mvs(d_box, inner_mvs);
    // auto inner_mvs = find_inner(mvs, box, frame);
    // auto d_box = average_mvs(inner_mvs);
    auto d_box = average_inner(mvs, box, frame);
    move_bbox(box, d_box, frame);
  }

  tracking(boxes);

  auto fuga = std::make_unique<Track>(tracks);
  auto hoge = std::make_pair(std::move(frame), std::move(fuga));
  push_back(out_fifo, hoge);
#ifdef THREAD
});
#endif
}

void MVTracker::sync()
{
#ifdef THREAD
  thr.join();
#endif
}
