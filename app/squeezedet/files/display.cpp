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
}

void Display::post_frame()
{
  system_clock::time_point start, end;
#ifdef THREAD
  thr = std::thread([&] {
#endif
    // std::tie(frame, objs) = pop_front(fifo);
  start = system_clock::now();
    auto hoge = pop_front(fifo);
  end = system_clock::now();
  cout << "auto hoge = pop_front(fifo)" << ":\t"
       << duration_cast<microseconds>(end-start).count() << " [us]" << endl;
    // std::tie(frame, objs) = std::move(hoge);
  start = system_clock::now();
    frame = std::move(hoge.first);
  end = system_clock::now();
  cout << "frame = std::move(hoge.first)" << ":\t"
       << duration_cast<microseconds>(end-start).count() << " [us]" << endl;
  start = system_clock::now();
    objs = std::move(hoge.second);
  end = system_clock::now();
  cout << "objs = std::move(hoge.second)" << ":\t"
       << duration_cast<microseconds>(end-start).count() << " [us]" << endl;

    cv::Mat img(frame->height, frame->width, CV_8UC3, frame->src);

    // delete [] frame->body;

    // TODO: overlay bounding-boxes, object-class and tracked-ids
  start = system_clock::now();
    for (auto& obj : *objs) {
      const int id = obj.first;
      const BBox box = obj.second;
      cv::rectangle(img,
                    cv::Point(box.left, box.top), cv::Point(box.right, box.bot),
                    color_map[box.name], 1);
      assert(!id);
    }
  end = system_clock::now();
  cout << "rectangle" << ":\t"
       << duration_cast<microseconds>(end-start).count() << " [us]" << endl;

  start = system_clock::now();
#ifndef RELEASE
    out.write(img);
#else
    cv::imshow("display", img);
#endif
  end = system_clock::now();
  cout << "display" << ":\t"
       << duration_cast<microseconds>(end-start).count() << " [us]" << endl;
  start = system_clock::now();
    cv::waitKey(1);
  end = system_clock::now();
  cout << "waitKey" << ":\t"
       << duration_cast<microseconds>(end-start).count() << " [us]" << endl;
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
