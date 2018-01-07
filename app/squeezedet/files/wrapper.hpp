#ifndef _WRAPPER_HPP_
#define _WRAPPER_HPP_

#include <deque>
#include <memory>
#include <vector>

#include "types.h"
#include "peta.h"
#include "util.h"
#include "layer.h"

void exec_cores(std::vector<Layer *> ls);

void assign_maps(std::vector<Layer *> ls,
                 std::vector<u32 *> weights, std::vector<u32 *> biases);

void undef_layers(std::vector<Layer *> ls);

template <typename T>
static T eat_front(std::shared_ptr<std::deque<T>> fifo)
{
  T tmp = fifo->front();
  fifo->pop_front();
  return tmp;
};

template <typename T>
static T eat_back(std::shared_ptr<std::deque<T>> fifo)
{
  T tmp = fifo->back();
  fifo->pop_back();
  return tmp;
};

#endif
