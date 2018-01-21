#ifndef _WRAPPER_HPP_
#define _WRAPPER_HPP_

#include <iostream>
#include <chrono>
#include <deque>
#include <mutex>
#include <memory>
#include <vector>

#include "kinpira.h"

#define THREAD
// #define RELEASE

using std::cout;
using std::endl;
using namespace std::chrono;

void exec_cores(std::vector<Layer *> ls);

#ifdef QUANT
void assign_maps_quant(
    std::vector<Layer *> ls,
    std::vector<u8 *> weights, std::vector<u8 *> biases,
    std::vector<float> weights_min, std::vector<float> weights_max,
    std::vector<float> biases_min, std::vector<float> biases_max);
#else
void assign_maps(std::vector<Layer *> ls,
                 std::vector<s16 *> weights, std::vector<s16 *> biases);
#endif

void undef_layers(std::vector<Layer *> ls);

void undef_maps(std::vector<Map *> ms);

extern std::mutex mtx;

template <typename T>
T pop_front(std::shared_ptr<std::deque<T>> fifo)
{
  std::lock_guard<std::mutex> lock(mtx);
  T tmp = fifo->front();
  fifo->pop_front();
  return tmp;
};

template <typename T>
T pop_back(std::shared_ptr<std::deque<T>> fifo)
{
  std::lock_guard<std::mutex> lock(mtx);
  T tmp = fifo->back();
  fifo->pop_back();
  return tmp;
};

template <typename T>
void push_front(std::shared_ptr<std::deque<T>> fifo, T tmp)
{
  std::lock_guard<std::mutex> lock(mtx);
  fifo->push_front(tmp);
};

template <typename T>
void push_back(std::shared_ptr<std::deque<T>> fifo, T tmp)
{
  std::lock_guard<std::mutex> lock(mtx);
  fifo->push_back(tmp);
};

#endif
