#include <deque>
#include <memory>
#include <thread>
#include <vector>

#include "bbox_utils.hpp"
#include "squeezedet.hpp"
#include "webcam.hpp"
#include "display.hpp"
#include "tracker.hpp"
#include "wrapper.hpp"

uint32_t *port;
uint32_t (*mem_renkon)[RENKON_WORDS];
uint32_t (*mem_gobou)[GOBOU_WORDS];
int16_t *mem_image;
#ifdef THREAD
std::mutex mtx;
#endif

// TODO: implementation
bool loop_continue()
{
#if 0
  static int end_cnt = 0;

  if (end_cnt++ == 10)
    return false;
  else
    return true;
#else
  return true;
#endif
}

inline void set_image(const std::shared_ptr<Image> &in_det, const Image &image)
{
  in_det->scales  = image.scales;
  in_det->height  = image.height;
  in_det->width   = image.width;
  in_det->src     = image.src;
  in_det->mvs     = image.mvs;
  memmove(in_det->body, image.body, sizeof(s16)*3*image.height*image.width);
}

void loop_scenario(const int gop_size = 12)
{
  system_clock::time_point start, end;
  system_clock::time_point clk;
  auto in_fifo  = std::make_shared<std::deque<Image>>();
  auto out_fifo = std::make_shared<std::deque<std::pair<Image, Track>>>();
  auto in_det   = std::make_shared<Image>();
  auto out_det  = std::make_shared<std::pair<Image, Mask>>();

  Webcam cam(in_fifo);
  SqueezeDet model(in_det, out_det);
  MVTracker me(in_fifo, out_fifo, out_det);
  Display disp(out_fifo);

  // blocking
  SHOW(cam.get_i_frame());

  // SHOW(*in_det = pop_front(in_fifo));
  SHOW(set_image(in_det, pop_front(in_fifo)));
  SHOW(model.evaluate());
  SHOW(cam.get_sub_gop());

  SHOW(model.sync());
  SHOW(me.annotate());
  SHOW(cam.sync());

  do {
    // printf("... ");
    SHOW(me.sync());

    // SHOW(*in_det = pop_back(in_fifo));
    SHOW(set_image(in_det, pop_back(in_fifo)));
    SHOW(model.evaluate());
    SHOW(disp.post_frame());
    SHOW(cam.get_sub_gop());

      // printf("■");
    for (int i = 0; i < gop_size-1; ++i) {
      clk = std::chrono::system_clock::now();

      SHOW(me.interpolate());

      SHOW(disp.sync());
      SHOW(me.sync());

      SHOW(disp.post_frame());

#ifdef RELEASE
      // SHOW(std::this_thread::sleep_until(clk + std::chrono::milliseconds(200)));
      SHOW(std::this_thread::sleep_until(clk + std::chrono::milliseconds(134)));
#endif
      // printf(" ■");
    }
    puts("");

    SHOW(model.sync());
    SHOW(me.annotate());
    SHOW(disp.sync());
    SHOW(cam.sync());
  } while (cam.has_frames());
}

int main(void)
{
  setbuf(stdout, NULL);
  printf("\033[2J");
  puts("### squeezedet\n");

  loop_scenario();

  return 0;
}
