#include "display.hpp"
#include "wrapper.hpp"

Display::Display(
  const std::shared_ptr<std::deque<std::pair<Image, Track>>> &fifo)
  : fifo(fifo)
  , color_map{ {"car",        cv::Scalar(255,   0,   0)}
             , {"pedestrian", cv::Scalar(  0, 255,   0)}
             , {"cyclist",    cv::Scalar(  0,   0, 255)}
             }
{
  // out.open(filename, cv::VideoWriter::fourcc('M', 'P', '4', 'V'),
  //          5.0, cv::Size(640, 480));
}

Display::~Display()
{
}

void Display::post_frame()
{
#ifdef THREAD
  thr = std::thread([&] {
#endif
    std::tie(frame, objs) = pop_front(fifo);

    cv::Mat img(frame.height, frame.width, CV_8UC3, frame.src);

    // delete [] frame.body;

    // TODO: overlay bounding-boxes, object-class and tracked-ids
    for (auto& obj : objs) {
      const int id = obj.first;
      const BBox box = obj.second;
      cv::rectangle(img,
                    cv::Point(box.left, box.top), cv::Point(box.right, box.bot),
                    color_map[box.name], 1);
    }

#ifdef RELEASE
    // out.write(img);
    cv::imshow("display", img);
#endif
    cv::waitKey(1);
#ifdef THREAD
  });
#endif
}

void Display::sync()
{
#ifdef THREAD
  thr.join();
#endif
}
