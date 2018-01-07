#include <cassert>

#include "wrapper.hpp"
#include "peta.h"
#include "util.h"
#include "layer.h"

void exec_cores(std::vector<Layer *> ls)
{
  for (auto l : ls)
    exec_core(l);
}

void assign_maps(std::vector<Layer *> ls,
                 std::vector<u32 *> weights, std::vector<u32 *> biases)
{
  const int size = ls.size();
  assert(ls.size() == weights.size() && ls.size() == biases.size());

  for (int i = 0; i < size; ++i)
    assign_map(ls[i], weights[i], biases[i]);
}

void undef_layers(std::vector<Layer *> ls)
{
  for (auto l : ls)
    undef_layer(l);
}
