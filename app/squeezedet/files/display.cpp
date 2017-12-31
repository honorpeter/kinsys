#include "display.hpp"
#include "wrapper.hpp"

Display::Display(std::shared_ptr<std::deque<std::pair<Image, Track>>> fifo)
  : fifo(fifo)
{
}

Display::~Display()
{
}

void Display::post_frame()
{
  Image frame;
  Track objs;
  std::tie(frame, objs) = eat_front(fifo);

  cv::Mat img(frame.height, frame.width, CV_8UC3, frame.body.data());

  // TODO: overlay bounding-boxes, object-class and tracked-ids
  for (auto& obj : objs) {
    std::make_pair(obj.first, obj.second);
    break;
  }

  cv::imshow("display", img);
  cv::waitKey(1);
}
