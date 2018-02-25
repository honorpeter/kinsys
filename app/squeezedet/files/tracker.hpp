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
    const std::shared_ptr<std::deque<std::unique_ptr<Image>>> &in_fifo,
    const std::shared_ptr<std::deque<
      std::pair<std::unique_ptr<Image>, std::unique_ptr<Track>>>> &out_fifo,
    const std::shared_ptr<std::pair<Image, Mask>> &out_det);
  ~MVTracker();

  void annotate();
  void interpolate();

  void sync();

private:
  std::thread thr;

  void predict(const Mask& boxes);
  void associate(const Mask& boxes);
  void tracking(const Mask& boxes);
  int assign_id();

  Mat3D<int> find_inner(const std::unique_ptr<Mat3D<int>> &mvs,
                        const BBox& box,
                        const std::unique_ptr<Image>& frame);
  std::array<float, 2> average_mvs(const Mat3D<int>& inner_mvs,
                                   float filling_rate=0.5);
  BBox move_bbox(BBox& box, std::array<float, 2>& d_box,
                 std::unique_ptr<Image>& frame);

  cv::KalmanFilter kalman;

  std::shared_ptr<std::deque<std::unique_ptr<Image>>> in_fifo;
  std::shared_ptr<std::deque<
    std::pair<std::unique_ptr<Image>, std::unique_ptr<Track>>>> out_fifo;
  std::shared_ptr<std::pair<Image, Mask>> out_det;

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

  // std::unique_ptr<Image> frame;
  // std::unique_ptr<Mat3D<int>> mvs;
  // Mat3D<int> inner_mvs;
  // std::array<float, 2> d_box;
};

#endif
