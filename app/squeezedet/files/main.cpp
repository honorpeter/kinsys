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

// TODO: judge_end implementation
bool judge_end()
{
  static int end_cnt = 0;

  if (end_cnt++ == 2)
    return true;
  else
    return false;
}

void loop_scenario(const int gop_size = 12)
{
  auto in_fifo  = std::make_shared<std::deque<Image>>();
  auto out_fifo = std::make_shared<std::deque<std::pair<Image, Track>>>();
  auto in_det   = std::make_shared<Image>();
  auto out_det  = std::make_shared<std::pair<Image, Mask>>();

  Webcam cam(in_fifo);
  SqueezeDet model(in_det, out_det);
  MVTracker me(in_fifo, out_fifo, out_det);
  Display disp(out_fifo);

  // blocking
  cam.get_i_frame();

  in_det = std::make_shared<Image>(eat_front(in_fifo));
  model.evaluate();
  cam.get_sub_gop();

  model.sync();
  cam.sync();

  do {
    me.annotate();
    me.sync();

    disp.post_frame();
    in_det = std::make_shared<Image>(eat_back(in_fifo));
    model.evaluate();
    cam.get_sub_gop();

    for (int i = 0; i < gop_size-1; ++i) {
      me.interpolate();

      disp.sync();
      me.sync();

      disp.post_frame();

      // TODO: Time Keep
      while (false);
    }

    disp.sync();
    model.sync();
    cam.sync();
  } while (judge_end());
}

int main(void)
{
  loop_scenario();

  return 0;
}
