#ifndef _DISPLAY_HPP_
#define _DISPLAY_HPP_

#include <deque>
#include <memory>
#include <thread>
#include <unordered_map>

#include <opencv2/opencv.hpp>

#include "bbox_utils.hpp"

class Display
{
public:
  Display(const std::shared_ptr<std::deque<std::pair<Image, Track>>> &fifo);
  ~Display();

  void post_frame();

  void sync();

private:
  std::thread thr;
  std::shared_ptr<std::deque<std::pair<Image, Track>>> fifo;

  std::unordered_map<std::string, cv::Scalar> color_map;

  cv::VideoWriter out;
  const std::string filename = "out.mp4";
};

#endif
