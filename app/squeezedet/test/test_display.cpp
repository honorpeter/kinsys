#include "display.hpp"

bool test_display()
{
  auto fifo = std::make_shared<std::deque<std::pair<Image, Track>>>();
  Display disp(fifo);

  return true;
}

int main(void)
{
  assert(test_display());

  return 0;
}
