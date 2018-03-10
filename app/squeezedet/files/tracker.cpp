#include <unordered_map>

#include "tracker.hpp"
#include "wrapper.hpp"
#include "arithmetic.hpp"
#include "hungarian.hpp"

#define KALMAN

static cv::Mat calc_center(const BBox& box)
{
  auto mean = [](auto x, auto y) {
    return static_cast<float>(x+y)/2.0f;
  };

  auto center_x = mean(box.left, box.right);
  auto center_y = mean(box.top, box.bot);

  auto center = cv::Mat(2, 1, CV_32F);
  center.at<float>(0) = center_x;
  center.at<float>(1) = center_y;

  return center;
}

KalmanInterpolator::KalmanInterpolator(int dp, int mp, int cp,
                                       float processNoise,
                                       float measurementNoise)
  : processNoise(processNoise)
  , measurementNoise(measurementNoise)
{
  const int initial_size = 16;

  total = 0;
  count = 0;
  stateList.reserve(initial_size);
  errorCovList.reserve(initial_size);

  kalman.init(dp, mp, cp, CV_32F);
  kalman.transitionMatrix    = cv::Mat::eye(dp, dp, CV_32F) * 1.0;
  kalman.controlMatrix       = cv::Mat::eye(dp, cp, CV_32F) * 1.0;
  kalman.measurementMatrix   = cv::Mat::eye(mp, dp, CV_32F) * 1.0;
  kalman.processNoiseCov     = cv::Mat::eye(dp, dp, CV_32F) * processNoise;
  kalman.measurementNoiseCov = cv::Mat::eye(mp, mp, CV_32F) * measurementNoise;

  noise = cv::Mat(mp, 1, CV_32F);
}

KalmanInterpolator::~KalmanInterpolator()
{
}

void KalmanInterpolator::reset(const Mask& boxes)
{
  total = (int)boxes.size();
  count = 0;
  stateList.clear();
  errorCovList.clear();

  for (int i = 0; i < (int)boxes.size(); ++i) {
    stateList.emplace_back(calc_center(boxes[i]));
    errorCovList.emplace_back(1.0 * cv::Mat::eye(dp, dp, CV_32F));
  }
}

void KalmanInterpolator::predict(cv::Mat& state, const cv::Mat& control)
{
  kalman.statePost = stateList[count];
  kalman.errorCovPost = errorCovList[count];
  state = kalman.predict(control);
}

void KalmanInterpolator::update(const cv::Mat& measurement)
{
  kalman.correct(measurement);
  stateList[count] = kalman.statePost;
  errorCovList[count] = kalman.errorCovPost;
}

cv::Mat KalmanInterpolator::filter(const cv::Mat& d_box)
{
  predict(state, d_box);
  cv::randn(noise, 0.0f, 1.0f);

  auto new_state = kalman.measurementMatrix * state
                  + kalman.measurementNoiseCov * noise;
  update(new_state);

  if (count == total-1)
    count = 0;
  else
    count += 1;

  return state;
}

MVTracker::MVTracker(
  const std::shared_ptr<std::deque<std::unique_ptr<Image>>>& in_fifo,
  const std::shared_ptr<std::deque<
    std::pair<std::unique_ptr<Image>, std::unique_ptr<Track>>>>& out_fifo,
  const std::shared_ptr<std::pair<Image, Mask>> &out_det)
  : in_fifo(in_fifo), out_fifo(out_fifo), out_det(out_det)
{
}

MVTracker::~MVTracker()
{
  if (thr.joinable())
    thr.join();
}

void MVTracker::predict(const Mask& boxes)
{
  // nop
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

void MVTracker::tracking(const Mask& boxes)
{
#if 1
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

int MVTracker::assign_id()
{
  return id++;
}

cv::Mat MVTracker::average_inner(
  const std::unique_ptr<std::vector<AVMotionVector>>& mvs,
  const BBox& box,
  const std::unique_ptr<Image>& frame,
  const float filling_rate)
{
  cv::Mat d_box = cv::Mat::zeros(2, 1, CV_32F);

  int box_size = 0;
  for (const AVMotionVector& mv : *mvs) {
    // const int y = std::max(0, std::min((int)mv.dst_y, frame->height - 1));
    // const int x = std::max(0, std::min((int)mv.dst_x, frame->width - 1));
    const int y = std::max(0, std::min((int)mv.src_y, frame->height - 1));
    const int x = std::max(0, std::min((int)mv.src_x, frame->width - 1));

    if ((box.top <= y && y < box.bot) && (box.left <= x && x < box.right)) {
      const float mvdx = mv.dst_x - mv.src_x;
      const float mvdy = mv.dst_y - mv.src_y;

      d_box.at<float>(0) += mvdx;
      d_box.at<float>(1) += mvdy;

      ++box_size;
    }
  }

  if (box_size == 0)
    return d_box;

  for (int k = 0; k < 2; ++k) {
    d_box.at<float>(k) /= static_cast<float>(box_size);
    d_box.at<float>(k) *= (1.0f / filling_rate);
  }

  return d_box;
}

void MVTracker::move_bbox(BBox& box,
                          const cv::Mat& d_box,
                          const std::unique_ptr<Image>& frame)
{
#ifdef KALMAN
  auto center = calc_center(box);
  auto new_center = kalman.filter(d_box);
  cv::Mat trans = new_center - center;

  box.name  = box.name;
  box.prob  = box.prob;
  box.left  = clip<int>(box.left  + trans.at<float>(0), 0, frame->width-1);
  box.top   = clip<int>(box.top   + trans.at<float>(1), 0, frame->height-1);
  box.right = clip<int>(box.right + trans.at<float>(0), 0, frame->width-1);
  box.bot   = clip<int>(box.bot   + trans.at<float>(1), 0, frame->height-1);
#else
  box.name  = box.name;
  box.prob  = box.prob;
  box.left  = clip<int>(box.left  + d_box.at<float>(0), 0, frame->width-1);
  box.top   = clip<int>(box.top   + d_box.at<float>(1), 0, frame->height-1);
  box.right = clip<int>(box.right + d_box.at<float>(0), 0, frame->width-1);
  box.bot   = clip<int>(box.bot   + d_box.at<float>(1), 0, frame->height-1);
#endif
}

void MVTracker::annotate()
{
#ifdef THREAD
thr = std::thread([&] {
#endif
  Image frame;
  std::tie(frame, boxes) = std::move(*out_det);

  tracking(boxes);
#ifdef KALMAN
  kalman.reset(boxes);
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
