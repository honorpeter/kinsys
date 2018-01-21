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

#define SHOW(func) { \
  start = system_clock::now(); \
  (func); \
  end = system_clock::now(); \
  cout << #func << ":\t" \
       << duration_cast<milliseconds>(end-start).count() << " [ms]" << endl; \
}

uint32_t *port;
uint32_t (*mem_renkon)[RENKON_WORDS];
uint32_t (*mem_gobou)[GOBOU_WORDS];

// TODO: implementation
bool loop_continue()
{
#if 1
  static int end_cnt = 0;

  if (end_cnt++ == 10)
    return false;
  else
    return true;
#else
  return true;
#endif
}

void loop_scenario(const int gop_size = 12)
{
  system_clock::time_point start, end;
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

  SHOW(*in_det = eat_front(in_fifo));
  SHOW(model.evaluate());
  SHOW(cam.get_sub_gop());

  SHOW(model.sync());
  SHOW(cam.sync());

  do {
    SHOW(me.annotate());
    SHOW(me.sync());

    SHOW(disp.post_frame());
    SHOW(*in_det = eat_back(in_fifo));
    SHOW(model.evaluate());
    SHOW(cam.get_sub_gop());

    for (int i = 0; i < gop_size-1; ++i) {
      SHOW(me.interpolate());

      SHOW(disp.sync());
      SHOW(me.sync());

      SHOW(disp.post_frame());

      // TODO: Time Keep
      // while (false);
      /* SHOW(std::this_thread::sleep_for(std::chrono::milliseconds(34))); */
    }

    SHOW(disp.sync());
    SHOW(model.sync());
    SHOW(cam.sync());
  } while (loop_continue());
}

int main(void)
{
  loop_scenario();

  return 0;
}
