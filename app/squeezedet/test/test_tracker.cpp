#include <cassert>

#include "tracker.hpp"

bool test_tracker()
{
  auto in_fifo = std::make_shared<std::deque<Image>>();
  auto out_fifo = std::make_shared<std::deque<std::pair<Image, Track>>>();
  auto out_det = std::make_shared<std::pair<Image, Mask>>();
  MVTracker me(in_fifo, out_fifo, out_det);

  return true;
}

int main(void)
{
  assert(test_tracker());

  return 0;
}
