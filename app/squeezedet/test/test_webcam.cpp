#include <iostream>

#include "webcam.hpp"

bool test_webcam()
{
  auto fifo = std::make_shared<std::deque<Image>>();
  Webcam cam(fifo);

  cam.get_i_frame();
  for (int i = 0; i < 3; ++i)
    cam.get_sub_gop();

  // int idx = 0;
  // for (auto x : fifo->front()) {
  //   std::cout << idx << ", " << x << std::endl;
  //   ++idx;
  // }

  if (fifo->size() == 37)
    return true;
  else
    return false;
}

int main(void)
{
  assert(test_webcam());

  return 0;
}
