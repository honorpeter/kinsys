#include <algorithm>

#include "webcam.hpp"
#include "wrapper.hpp"

Webcam::Webcam(
  const std::shared_ptr<std::deque<std::unique_ptr<Image>>>& fifo)
  : fifo(fifo)
{
  av_register_all();
  avdevice_register_all();

#ifdef RELEASE
  const char *name = "/dev/video0";
  AVInputFormat *in_format = av_find_input_format("v4l2");
  AVDictionary *format_opts = nullptr;
  // av_dict_set(&format_opts, "framerate", "10", 0);
  av_dict_set(&format_opts, "framerate", "30", 0);
  // av_dict_set(&format_opts, "video_size", "176x144", 0);
  av_dict_set(&format_opts, "video_size", "320x240", 0);
  av_dict_set(&format_opts, "pixel_format", "bgr0", 0);
  av_dict_set(&format_opts, "input_format", "h264", 0);

  // const char *name = "/usr/share/squeezedet/data/taxi.mp4";
  // AVInputFormat *in_format = av_find_input_format("avc1");
  // AVDictionary *format_opts = nullptr;
  // av_dict_set(&format_opts, "framerate", "30", 0);
  // av_dict_set(&format_opts, "video_size", "176x144", 0);
  // av_dict_set(&format_opts, "pixel_format", "bgr0", 0);
#else
  // const char *name = "taxi.mp4";
  // AVInputFormat *in_format = av_find_input_format("avc1");
  // AVDictionary *format_opts = nullptr;
  // av_dict_set(&format_opts, "framerate", "30", 0);
  // av_dict_set(&format_opts, "video_size", "1248x384", 0);
  // av_dict_set(&format_opts, "pixel_format", "bgr0", 0);

  const char *name = "taxi2.mp4";
  AVInputFormat *in_format = av_find_input_format("avc1");
  AVDictionary *format_opts = nullptr;
  av_dict_set(&format_opts, "framerate", "30", 0);
  av_dict_set(&format_opts, "video_size", "640x480", 0);
  av_dict_set(&format_opts, "pixel_format", "bgr0", 0);

  // const char *name = "taxi3.mp4";
  // AVInputFormat *in_format = av_find_input_format("avc1");
  // AVDictionary *format_opts = nullptr;
  // av_dict_set(&format_opts, "framerate", "30", 0);
  // av_dict_set(&format_opts, "video_size", "320x240", 0);
  // av_dict_set(&format_opts, "pixel_format", "bgr0", 0);
#endif

  if (avformat_open_input(&format_ctx, name, in_format, &format_opts) != 0)
    throw std::runtime_error("input failed");

  if (avformat_find_stream_info(format_ctx, NULL) < 0)
    throw std::runtime_error("stream info not found");

  video_stream = -1;
  for (int i = 0; i < (int)format_ctx->nb_streams; ++i) {
    if (format_ctx->streams[i]->codec->codec_type == AVMEDIA_TYPE_VIDEO) {
      video_stream = i;
      break;
    }
  }
  if (video_stream == -1)
    throw std::runtime_error("video stream not found");

  codec_ctx = format_ctx->streams[video_stream]->codec;
  AVCodec *codec = avcodec_find_decoder(codec_ctx->codec_id);
  if (codec == NULL)
    throw std::runtime_error("Unsupported codec!");

  AVDictionary *codec_opts = NULL;
  av_dict_set(&codec_opts, "flags2", "+export_mvs", 0);
  if (avcodec_open2(codec_ctx, codec, &codec_opts) < 0)
    throw std::runtime_error("codec open failed");

  sws_ctx =
    sws_getContext(codec_ctx->width, codec_ctx->height, codec_ctx->pix_fmt,
                   codec_ctx->width, codec_ctx->height,
                   AV_PIX_FMT_BGR24, SWS_BILINEAR, NULL, NULL, NULL);

  frame = av_frame_alloc();
  frame_bgr = av_frame_alloc();
  if (frame == NULL || frame_bgr == NULL)
    throw std::runtime_error("frame allocation failed");

  num_bytes = avpicture_get_size(AV_PIX_FMT_BGR24,
                                 codec_ctx->width, codec_ctx->height);
  buffer = (uint8_t *)av_malloc(sizeof(uint8_t) * num_bytes);

  avpicture_fill((AVPicture *)frame_bgr, buffer, AV_PIX_FMT_BGR24,
                 codec_ctx->width, codec_ctx->height);

  imgbuf.reserve(gop_size-1);
}

Webcam::~Webcam()
{
#if 0
  av_free(buffer);
  av_free(frame_bgr);
  av_free(frame);

  avformat_close_input(&format_ctx);
  avcodec_close(codec_ctx);
#endif

  if (thr.joinable())
    thr.join();
}

void Webcam::extract_mvs(AVFrame* frame, std::vector<AVMotionVector>& mvs)
{
  AVFrameSideData *side =
    av_frame_get_side_data(frame, AV_FRAME_DATA_MOTION_VECTORS);
  if (side == NULL) {
    mvs = std::vector<AVMotionVector>();
  }
  else {
    int mvcount = side->size / sizeof(AVMotionVector);
    AVMotionVector *mvarray = (AVMotionVector *)side->data;

    mvs = std::vector<AVMotionVector>(mvarray, mvarray + mvcount);
  }
}

void Webcam::format_mvs(std::unique_ptr<Image>& img,
                        const std::vector<AVMotionVector>& mvs)
{
#if 0
  // const int flow_rows = std::min(img.height / mb_size, max_mb_size);
  // const int flow_cols = std::min(img.width / mb_size, max_mb_size);
  const int flow_rows = img->height;
  const int flow_cols = img->width;
  // auto flow = zeros<int>(flow_rows, flow_cols, 2);

  for (const AVMotionVector& mv : mvs) {
    int mvdx = mv.dst_x - mv.src_x;
    int mvdy = mv.dst_y - mv.src_y;

    // size_t i_clipped = std::max(0, std::min(mv.dst_y / mb_size, flow_rows - 1));
    // size_t j_clipped = std::max(0, std::min(mv.dst_x / mb_size, flow_cols - 1));
    size_t i_clipped = std::max(0, std::min((int)mv.dst_y, flow_rows - 1));
    size_t j_clipped = std::max(0, std::min((int)mv.dst_x, flow_cols - 1));

    flow[i_clipped][j_clipped][0] = mvdx;
    flow[i_clipped][j_clipped][1] = mvdy;
  }

  img->mvs = std::make_unique<Mat3D<int>>(flow);
#else
  img->mvs = std::make_unique<std::vector<AVMotionVector>>(std::move(mvs));
#endif
}

void Webcam::preprocess(cv::Mat& img, const std::vector<AVMotionVector>& mvs)
{
  const int in_c = img.channels();
  const int in_h = img.rows;
  const int in_w = img.cols;

  auto target = std::make_unique<Image>();
  target->height = in_h;
  target->width  = in_w;

  format_mvs(target, mvs);

  cv::Mat img_f;

  target->src = img.data;

  // img.copyTo(img_i);
  img.convertTo(img_f, CV_32FC3);
  // target->body = new s32[in_c * in_h * in_w];
  target->body = std::make_unique<s32[]>(in_c * in_h * in_w);

  int idx = 0;
  for (int k = 0; k < in_c; ++k) {
    for (int i = 0; i < in_h; ++i) {
      for (int j = 0; j < in_w; ++j) {
        float acc = img_f.at<cv::Vec3f>(i, j)[k] - bgr_means[k];
        acc /= 255.0;
        target->body[idx] = static_cast<s32>(rint(acc*pixel_offset));
        ++idx;
      }
    }
  }

  push_back(fifo, target);
}

void Webcam::get_i_frame()
{
  char pict_type = 0;
  do {
    int read_frame = av_read_frame(format_ctx, &packet);
    if (read_frame < 0)
      continue;
      // throw std::runtime_error("read failed");

    if (packet.stream_index != video_stream)
      continue;

    int got_frame = 0;
    avcodec_decode_video2(codec_ctx, frame, &got_frame, &packet);
    if (!got_frame)
      continue;
      // throw std::runtime_error("frame was not obtained");

    pict_type = av_get_picture_type_char(frame->pict_type);
  } while (pict_type != 'I');

  sws_scale(sws_ctx, (uint8_t const * const *)frame->data,
            frame->linesize, 0, codec_ctx->height,
            frame_bgr->data, frame_bgr->linesize);

  extract_mvs(frame, mvs);

  av_packet_unref(&packet);

  imgbuf.emplace_back(buffer, buffer+num_bytes);
  cv::Mat img(codec_ctx->height, codec_ctx->width,
              CV_8UC3, imgbuf.back().data());

  preprocess(img, mvs);
}

void Webcam::get_sub_gop()
{
#ifdef THREAD
  thr = std::thread([&] {
#endif
    if ((int)imgbuf.size() > gop_size+1)
      imgbuf.clear();

    for (int i = 0; i < sub_gop_size; ++i) {
      if (av_read_frame(format_ctx, &packet) < 0) {
        has_frame = false;
        return;
        --i;
        continue;
        // throw std::runtime_error("read failed");
      }

      if (packet.stream_index != video_stream) {
        // has_frame = false;
        // return;
        --i;
        continue;
      }

      int got_frame;
      avcodec_decode_video2(codec_ctx, frame, &got_frame, &packet);
      if (!got_frame) {
        // has_frame = false;
        // return;
        --i;
        continue;
        // throw std::runtime_error("frame was not obtained");
      }

      sws_scale(sws_ctx, (uint8_t const * const *)frame->data,
                frame->linesize, 0, codec_ctx->height,
                frame_bgr->data, frame_bgr->linesize);

      extract_mvs(frame, mvs);

      imgbuf.emplace_back(buffer, buffer+num_bytes);
      cv::Mat img(codec_ctx->height, codec_ctx->width,
                  CV_8UC3, imgbuf.back().data());

      preprocess(img, mvs);
    }
#ifdef THREAD
  });
#endif
}

bool Webcam::has_frames()
{
  return has_frame;
}

void Webcam::sync()
{
#ifdef THREAD
  thr.join();
#endif
}
