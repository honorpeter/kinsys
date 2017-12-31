#ifndef _WEBCAM_HPP_
#define _WEBCAM_HPP_

#include <deque>
#include <memory>

extern "C" {
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libswscale/swscale.h>
#include <libavutil/motion_vector.h>
#include <libavdevice/avdevice.h>
}

#include <opencv2/opencv.hpp>

#include "types.h"
#include "bbox_utils.hpp"

class Webcam
{
public:
  Webcam(std::shared_ptr<std::deque<Image>> fifo);
  ~Webcam();

  void get_i_frame();
  void get_sub_gop();

  void sync();

  // Logicool Webcam C920 H.264
  const int gop_size = 300;
  const int sub_gop_size = 12;

private:
  void preprocess(cv::Mat& img);

  std::shared_ptr<std::deque<Image>> fifo;

  AVFormatContext *format_ctx = nullptr;
  AVCodecContext *codec_ctx = nullptr;
  SwsContext *sws_ctx = nullptr;

  AVFrame *frame = nullptr;
  AVFrame *frame_bgr = nullptr;

  AVPacket packet;
  AVMotionVector *mvs = nullptr;

  uint8_t *buffer = nullptr;

  int video_stream;
};

#endif
