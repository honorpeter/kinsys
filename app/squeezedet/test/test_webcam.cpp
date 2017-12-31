#include <iostream>

#include "webcam.hpp"

bool test_webcam()
{
  auto fifo = std::make_shared<std::deque<Image>>();
  Webcam cam(fifo);

  for (int i = 0; i < 3; ++i)
    cam.get_i_frame();

  // int idx = 0;
  // for (auto x : fifo->front()) {
  //   std::cout << idx << ", " << x << std::endl;
  //   ++idx;
  // }

  if (fifo->size() == 3)
    return true;
  else
    return false;
}

int main(void)
{
  assert(test_webcam());

  return 0;
}
