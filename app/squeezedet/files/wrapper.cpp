#include <cassert>

#include "wrapper.hpp"
#include "kinpira.h"

void exec_cores(const std::vector<Layer *>& ls)
{
  for (auto l : ls)
    exec_core(l);
}

#ifdef __KPR_QUANT__
void assign_maps_quant(
    const std::vector<Layer *>& ls,
    const std::vector<u8 *>& weights,
    const std::vector<u8 *>& biases,
    int qbits,
    const std::vector<float>& weights_min,
    const std::vector<float>& weights_max,
    const std::vector<float>& biases_min,
    const std::vector<float>& biases_max)
{
  const int size = ls.size();
  assert(ls.size() == weights.size() && ls.size() == biases.size());

  for (int i = 0; i < size; ++i)
    assign_map_quant(
      ls[i], weights[i], biases[i],
      qbits, weights_min[i], weights_max[i], biases_min[i], biases_max[i]);
}
#else
void assign_maps(const std::vector<Layer *>& ls,
                 const std::vector<s16 *>& weights,
                 const std::vector<s16 *>& biases)
{
  const int size = ls.size();
  assert(ls.size() == weights.size() && ls.size() == biases.size());

  for (int i = 0; i < size; ++i)
    assign_map(ls[i], weights[i], biases[i]);
}
#endif

void undef_layers(std::vector<Layer *> ls)
{
  for (auto l : ls)
    undef_layer(l);
}

void undef_maps(std::vector<Map *> ms)
{
  for (auto m : ms)
    undef_map(m);
}
