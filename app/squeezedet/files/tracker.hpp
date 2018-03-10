#ifndef _TRACKER_HPP_
#define _TRACKER_HPP_

#include <deque>
#include <memory>
#include <thread>
#include <unordered_map>

#include <opencv2/opencv.hpp>
extern "C" {
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libswscale/swscale.h>
#include <libavutil/motion_vector.h>
#include <libavdevice/avdevice.h>
}

#include "kinpira.h"
#include "bbox_utils.hpp"

// delegated class for cv::KalmanFilter
class KalmanInterpolator
{
public:
  KalmanInterpolator(int dp=2, int mp=2, int cp=2,
                     float processNoise=1.0f, float measurementNoise=0.1f);
  ~KalmanInterpolator();

  void reset(const Mask& boxes);
  cv::Mat filter(const cv::Mat& d_box);

private:
  void predict(cv::Mat& state, const cv::Mat& control);
  void update(const cv::Mat& measurement);

  cv::KalmanFilter kalman;

  cv::Mat state;
  cv::Mat noise;

  const int dp = 2, mp = 2, cp = 2;
  const float processNoise = 1.0f;
  const float measurementNoise = 0.1f;

  int total;
  int count;
  std::vector<cv::Mat> stateList;
  std::vector<cv::Mat> errorCovList;
};

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

  cv::Mat average_inner(
    const std::unique_ptr<std::vector<AVMotionVector>>& mvs,
    const BBox& box,
    const std::unique_ptr<Image>& frame,
    const float filling_rate=0.8);
  void move_bbox(BBox& box,
                 const cv::Mat& d_box,
                 const std::unique_ptr<Image>& frame);

  KalmanInterpolator kalman;

  std::shared_ptr<std::deque<std::unique_ptr<Image>>> in_fifo;
  std::shared_ptr<std::deque<
    std::pair<std::unique_ptr<Image>, std::unique_ptr<Track>>>> out_fifo;
  std::shared_ptr<std::pair<Image, Mask>> out_det;

  Mask prev_boxes;
  Mask boxes;
  Track tracks;

  int id = 0;
  std::unordered_map<int, int> id_map;
  const float cost_thresh = 1.0;
};

#endif
