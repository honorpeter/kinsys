#include <cassert>

#include "wrapper.hpp"
#include "kinpira.h"

void exec_cores(std::vector<Layer *> ls)
{
  for (auto l : ls)
    exec_core(l);
}

#ifdef QUANT
void assign_maps_quant(
    std::vector<Layer *> ls,
    std::vector<u8 *> weights, std::vector<u8 *> biases,
    std::vector<float> weights_min, std::vector<float> weights_max,
    std::vector<float> biases_min, std::vector<float> biases_max)
{
  const int size = ls.size();
  assert(ls.size() == weights.size() && ls.size() == biases.size());
  // cout << ls.size() << " " << weights.size() << " " << biases.size()
  //      << " " << weights_min.size() << " " << weights_max.size()
  //      << " " << biases_min.size() << " " << biases_max.size() << endl;

  for (int i = 0; i < size; ++i)
    assign_map_quant(
        ls[i], weights[i], biases[i],
        weights_min[i], weights_max[i], biases_min[i], biases_max[i]);
}
#else
void assign_maps(std::vector<Layer *> ls,
                 std::vector<s16 *> weights, std::vector<s16 *> biases)
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
