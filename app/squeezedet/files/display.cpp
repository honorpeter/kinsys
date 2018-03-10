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
  //          30.0, cv::Size(1248, 384));

  out.open(filename, cv::VideoWriter::fourcc('a', 'v', 'c', '1'),
           30.0, cv::Size(640, 480));

  // out.open(filename, cv::VideoWriter::fourcc('a', 'v', 'c', '1'),
  //          30.0, cv::Size(320, 240));
#endif
}

Display::~Display()
{
  if (thr.joinable())
    thr.join();
}

void Display::draw_bbox(cv::Mat& img, std::pair<int, BBox>& obj)
{
  const int   id = obj.first;
  const BBox box = obj.second;

  const auto   text       = std::to_string(id);
  const int    font_face  = cv::FONT_HERSHEY_SIMPLEX;
  const double font_scale = 0.5;
  const int    thickness  = 1;

  int baseline = 0;
  const auto size = cv::getTextSize(text, font_face, font_scale,
                                    thickness, &baseline);

  cv::rectangle(img,
                cv::Point(box.left, box.top), cv::Point(box.right, box.bot),
                color_map[box.name], thickness);

  cv::rectangle(img,
                cv::Point(box.left, box.top),
                cv::Point(box.left+size.width+8, box.top+size.height+12),
                color_map[box.name], -1);
  cv::putText(img, text,
              cv::Point(box.left+4, box.top+size.height+4),
              font_face, font_scale,
              cv::Scalar(255, 255, 255)-color_map[box.name], thickness);
}

void Display::post_frame()
{
#ifdef THREAD
  thr = std::thread([&] {
#endif
    trk   = pop_front(fifo);
    frame = std::move(trk.first);
    objs  = std::move(trk.second);

    cv::Mat img(frame->height, frame->width, CV_8UC3, frame->src);

    for (auto& obj : *objs)
      draw_bbox(img, obj);

#ifndef RELEASE
    out.write(img);
#else
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
