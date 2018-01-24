#ifndef _TRACKER_HPP_
#define _TRACKER_HPP_

#include <deque>
#include <memory>
#include <thread>
#include <unordered_map>

#include <opencv2/opencv.hpp>

#include "kinpira.h"
#include "bbox_utils.hpp"

class MVTracker
{
public:
  MVTracker(
    const std::shared_ptr<std::deque<Image>> &in_fifo,
    const std::shared_ptr<std::deque<std::pair<Image, Track>>> &out_fifo,
    const std::shared_ptr<std::pair<Image, Mask>> &out_det);
  ~MVTracker();

  void annotate();
  void interpolate();

  void sync();

private:
  std::thread thr;

  void predict(Mask& boxes);
  void associate(Mask& boxes);
  void tracking(Image& frame, Mask& boxes);
  int assign_id();

  cv::KalmanFilter kalman;

  std::shared_ptr<std::deque<Image>> in_fifo;
  std::shared_ptr<std::deque<std::pair<Image, Track>>> out_fifo;
  std::shared_ptr<std::pair<Image, Mask>> out_det;

  Image frame;
  Mask prev_boxes;
  Mask boxes;
  Track tracks;

  const int dp = 2, mp = 2, cp = 2;
  const float processNoise = 1.0;
  const float measurementNoise = 0.1;

  int total;
  int count;
  std::vector<cv::Mat> stateList;
  std::vector<cv::Mat> errorCovList;

  std::unordered_map<int, int> id_map;
  const float cost_thresh = 1.0;
};

#endif
