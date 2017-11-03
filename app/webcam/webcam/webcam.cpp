#include <iostream>
#include "opencv2/opencv.hpp"

int main(int, char**)
{
  using namespace cv;

  VideoCapture cap(0); // open the default camera

  if (!cap.isOpened())  // check if we succeeded
    return -1;

  Mat edges;
  namedWindow("webcam", 1);
  for (;;) {
    Mat frame;

    cap >> frame; // get a new frame from camera
    // std::cout << "\033[2J"
    //           << "frame as numpy format:" << std::endl
    //           << format(frame, Formatter::FMT_NUMPY) << std::endl;
    cvtColor(frame, edges, COLOR_BGR2GRAY);
    GaussianBlur(edges, edges, Size(7,7), 1.5, 1.5);
    Canny(edges, edges, 0, 30, 3);
    imshow("edges", edges);
    // imshow("frame", frame);

    if (waitKey(30) >= 0)
      break;
  }

  // the camera will be deinitialized automatically in VideoCapture destructor
  return 0;
}
