#include "webcam.hpp"

static void my_vector_frame(AVFrame *frame, AVMotionVector *mvs)
{
}

Webcam::Webcam(std::shared_ptr<std::deque<Image>> fifo)
  : fifo(fifo)
{
  av_register_all();
  avdevice_register_all();

  const char *name = "/dev/video0";
  AVInputFormat *in_format = av_find_input_format("v4l2");
  AVDictionary *format_opts = nullptr;
  av_dict_set(&format_opts, "framerate", "30", 0);
  av_dict_set(&format_opts, "video_size", "640x480", 0);
  av_dict_set(&format_opts, "pixel_format", "bgr0", 0);
  av_dict_set(&format_opts, "input_format", "h264", 0);

  if (avformat_open_input(&format_ctx, name, in_format, &format_opts) != 0)
    throw "input failed";

  if (avformat_find_stream_info(format_ctx, NULL) < 0)
    throw "stream info not found";

  video_stream = -1;
  for (int i = 0; i < (int)format_ctx->nb_streams; ++i) {
    if (format_ctx->streams[i]->codec->codec_type == AVMEDIA_TYPE_VIDEO) {
      video_stream = i;
      break;
    }
  }
  if (video_stream == -1)
    throw "video stream not found";

  codec_ctx = format_ctx->streams[video_stream]->codec;
  AVCodec *codec = avcodec_find_decoder(codec_ctx->codec_id);
  if (codec == NULL)
    throw "Unsupported codec!";

  AVDictionary *codec_opts = NULL;
  av_dict_set(&codec_opts, "flags2", "+export_mvs", 0);
  if (avcodec_open2(codec_ctx, codec, &codec_opts) < 0)
    throw "codec open failed";

  sws_ctx =
    sws_getContext(codec_ctx->width, codec_ctx->height, codec_ctx->pix_fmt,
                   codec_ctx->width, codec_ctx->height,
                   AV_PIX_FMT_BGR24, SWS_BILINEAR, NULL, NULL, NULL);

  frame = av_frame_alloc();
  frame_bgr = av_frame_alloc();
  if (frame == NULL || frame_bgr == NULL)
    throw "frame allocation failed";

  int num_bytes = avpicture_get_size(AV_PIX_FMT_BGR24,
                                     codec_ctx->width, codec_ctx->height);
  buffer = (uint8_t *)av_malloc(sizeof(uint8_t) * num_bytes);

  avpicture_fill((AVPicture *)frame_bgr, buffer, AV_PIX_FMT_BGR24,
                 codec_ctx->width, codec_ctx->height);
}

Webcam::~Webcam()
{
  av_free(buffer);
  av_free(frame_bgr);
  av_free(frame);

  avformat_close_input(&format_ctx);
  avcodec_close(codec_ctx);

}

void Webcam::preprocess(cv::Mat& img)
{
  const int in_c = img.channels();
  const int in_h = img.rows;
  const int in_w = img.cols;

  // Image target(in_c * in_h * in_w);
  target  = Image(in_c, in_h, in_w, img.data);

  cv::Mat frame_f;
  img.convertTo(frame_f, CV_32FC3);

  int idx = 0;
  const float BGR_MEANS[3] = {103.939, 116.779, 123.68};
  for (int k = 0; k < in_c; ++k) {
    for (int i = 0; i < in_h; ++i) {
      for (int j = 0; j < in_w; ++j) {
        float acc = frame_f.at<cv::Vec3f>(i, j)[k] - BGR_MEANS[k];
        acc /= 255.0;
        target.body[idx] = static_cast<s16>(acc*256.);
        ++idx;
      }
    }
  }
}

void Webcam::get_i_frame()
{
  char pict_type;
  do {
    if (av_read_frame(format_ctx, &packet) < 0)
      // throw "read failed";
      continue;

    if (packet.stream_index != video_stream)
      continue;

    int got_frame;
    avcodec_decode_video2(codec_ctx, frame, &got_frame, &packet);
    if (!got_frame)
      // throw "frame was not obtained";
      continue;

    pict_type = av_get_picture_type_char(frame->pict_type);
  } while (pict_type != 'I');

  sws_scale(sws_ctx, (uint8_t const * const *)frame->data,
            frame->linesize, 0, codec_ctx->height,
            frame_bgr->data, frame_bgr->linesize);

  my_vector_frame(frame, mvs);

  av_packet_unref(&packet);

  cv::Mat img(codec_ctx->height, codec_ctx->width,
              CV_8UC3, frame_bgr->data[0]);

  preprocess(img);
  fifo->push_back(target);
}

void Webcam::get_sub_gop()
{
  // thr = std::thread([&] {
    for (int i = 0; i < sub_gop_size; ++i) {
      if (av_read_frame(format_ctx, &packet) < 0)
      {
        --i;
        // throw "read failed";
        continue;
      }

      if (packet.stream_index != video_stream)
      {
        --i;
        continue;
      }

      int got_frame;
      avcodec_decode_video2(codec_ctx, frame, &got_frame, &packet);
      if (!got_frame)
      {
        --i;
        // throw "frame was not obtained";
        continue;
      }

      sws_scale(sws_ctx, (uint8_t const * const *)frame->data,
                frame->linesize, 0, codec_ctx->height,
                frame_bgr->data, frame_bgr->linesize);

      my_vector_frame(frame, mvs);

      cv::Mat img(codec_ctx->height, codec_ctx->width,
                  CV_8UC3, frame_bgr->data[0]);

      preprocess(img);
    }
  // });
}

void Webcam::sync()
{
  // thr.join();
  fifo->push_back(target);
}
