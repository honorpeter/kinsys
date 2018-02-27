#include "display.hpp"
#include "wrapper.hpp"

Display::Display(
  const std::shared_ptr<std::deque<
    std::pair<std::unique_ptr<Image>, std::unique_ptr<Track>>>> &fifo)
  : fifo(fifo)
  , color_map{ {"car",        cv::Scalar(255,   0,   0)}
             , {"pedestrian", cv::Scalar(  0, 255,   0)}
             , {"cyclist",    cv::Scalar(  0,   0, 255)}
             }
{
#ifndef RELEASE
  // out.open(filename, cv::VideoWriter::fourcc('a', 'v', 'c', '1'),
  //          30.0, cv::Size(240, 240));

  // out.open(filename, cv::VideoWriter::fourcc('a', 'v', 'c', '1'),
  //          30.0, cv::Size(1248, 384));

  out.open(filename, cv::VideoWriter::fourcc('a', 'v', 'c', '1'),
           30.0, cv::Size(640, 480));
#endif
}

Display::~Display()
{
  if (thr.joinable())
    thr.join();
}

void Display::post_frame()
{
#ifdef THREAD
  thr = std::thread([&] {
#endif
    // std::tie(frame, objs) = pop_front(fifo);
    auto hoge = pop_front(fifo);
    // std::tie(frame, objs) = std::move(hoge);
    frame = std::move(hoge.first);
    objs = std::move(hoge.second);

    cv::Mat img(frame->height, frame->width, CV_8UC3, frame->src);
    // delete [] frame->body;

    // TODO: overlay bounding-boxes, object-class and tracked-ids
    for (auto& obj : *objs) {
      const int id = obj.first;
      const BBox box = obj.second;
      cv::rectangle(img,
                    cv::Point(box.left, box.top), cv::Point(box.right, box.bot),
                    color_map[box.name], 1);
      assert(!id);
    }

#ifndef RELEASE
    out.write(img);
#else
    // cv::resize(img, img, cv::Size(640, 480));
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
