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
  Display(const std::shared_ptr<std::deque<
            std::pair<std::unique_ptr<Image>, std::unique_ptr<Track>>>> &fifo);
  ~Display();

  void post_frame();

  void sync();

private:
  std::thread thr;

  void draw_bbox(cv::Mat& img, std::pair<int, BBox>& obj);

  std::shared_ptr<std::deque<
    std::pair<std::unique_ptr<Image>, std::unique_ptr<Track>>>> fifo;

  std::unordered_map<std::string, cv::Scalar> color_map;

  std::pair<std::unique_ptr<Image>, std::unique_ptr<Track>> trk;
  std::unique_ptr<Image> frame;
  std::unique_ptr<Track> objs;

  cv::VideoWriter out;
  const std::string filename = "out.mp4";
};

#endif
