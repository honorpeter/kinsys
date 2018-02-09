#ifndef _WEBCAM_HPP_
#define _WEBCAM_HPP_

#include <deque>
#include <memory>
#include <thread>

extern "C" {
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libswscale/swscale.h>
#include <libavutil/motion_vector.h>
#include <libavdevice/avdevice.h>
}

#include <opencv2/opencv.hpp>

#include "kinpira.h"
#include "bbox_utils.hpp"

class Webcam
{
public:
  Webcam(const std::shared_ptr<std::deque<Image>> &fifo);
  ~Webcam();

  void get_i_frame();
  void get_sub_gop();

  void sync();

  // Logicool Webcam C920 H.264
  const int gop_size = 300;
  const int sub_gop_size = 12;
  const int mb_size = 16;
  const int max_mb_size = 512;
  const float pixel_offset = 1 << 14;
  const float bgr_means[3] = {103.939, 116.779, 123.68};

private:
  std::thread thr;

  void preprocess(cv::Mat& img, std::vector<AVMotionVector> &mvs);
  void extract_mvs(AVFrame *frame, std::vector<AVMotionVector> &mvs);
  void format_mvs(Image &img, std::vector<AVMotionVector> &mvs);

  std::shared_ptr<std::deque<Image>> fifo;
  Image target;

  AVFormatContext *format_ctx = nullptr;
  AVCodecContext *codec_ctx = nullptr;
  SwsContext *sws_ctx = nullptr;

  AVFrame *frame = nullptr;
  AVFrame *frame_bgr = nullptr;

  AVPacket packet;
  std::vector<AVMotionVector> mvs;

  uint8_t *buffer = nullptr;

  int video_stream;
};

#endif
