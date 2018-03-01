#ifndef _WRAPPER_HPP_
#define _WRAPPER_HPP_

#include <iostream>
#include <chrono>
#include <deque>
#include <mutex>
#include <memory>
#include <vector>

#include "kinpira.h"

// #define THREAD
// #define RELEASE

using std::cout;
using std::endl;
using namespace std::chrono;

#if 1
#define SHOW(func) { \
  start = system_clock::now(); \
  (func); \
  end = system_clock::now(); \
  cout << #func << ":\t" \
       << duration_cast<microseconds>(end-start).count() << " [us]" << endl; \
}
#else
#define SHOW(func) (func);
#endif

void exec_cores(const std::vector<Layer *>& ls);

#ifdef __KPR_QUANT__
void assign_maps_quant(
    const std::vector<Layer *>& ls,
    const std::vector<u8 *>& weights,
    const std::vector<u8 *>& biases,
    int qbits,
    const std::vector<float>& weights_min,
    const std::vector<float>& weights_max,
    const std::vector<float>& biases_min,
    const std::vector<float>& biases_max);
#else
void assign_maps(const std::vector<Layer *>& ls,
                 const std::vector<s32 *>& weights,
                 const std::vector<s32 *>& biases);
#endif

void undef_layers(std::vector<Layer *> ls);

void undef_maps(std::vector<Map *> ms);

#ifdef THREAD
extern std::mutex mtx;
#endif

template <typename T>
inline std::unique_ptr<T>
pop_front(const std::shared_ptr<std::deque<std::unique_ptr<T>>>& fifo)
{
#ifdef THREAD
  std::lock_guard<std::mutex> lock(mtx);
#endif
  auto tmp = std::move(fifo->front());
  fifo->pop_front();

  return std::move(tmp);
}

template <typename T1, typename T2>
inline std::pair<std::unique_ptr<T1>, std::unique_ptr<T2>>
pop_front(const std::shared_ptr<std::deque<std::pair<std::unique_ptr<T1>, std::unique_ptr<T2>>>>& fifo)
{
#ifdef THREAD
  std::lock_guard<std::mutex> lock(mtx);
#endif
  auto tmp = std::move(fifo->front());
  fifo->pop_front();

  return std::move(tmp);
}

template <typename T>
inline T pop_front(const std::shared_ptr<std::deque<T>>& fifo)
{
#ifdef THREAD
  std::lock_guard<std::mutex> lock(mtx);
#endif
  T tmp = fifo->front();
  fifo->pop_front();

  return tmp;
}

template <typename T>
inline std::unique_ptr<T>
pop_back(const std::shared_ptr<std::deque<std::unique_ptr<T>>>& fifo)
{
#ifdef THREAD
  std::lock_guard<std::mutex> lock(mtx);
#endif
  auto tmp = std::move(fifo->back());
  fifo->pop_back();

  return std::move(tmp);
}

template <typename T>
inline T pop_back(const std::shared_ptr<std::deque<T>>& fifo)
{
#ifdef THREAD
  std::lock_guard<std::mutex> lock(mtx);
#endif
  T tmp = fifo->back();
  fifo->pop_back();

  return tmp;
}

template <typename T>
inline void
push_front(const std::shared_ptr<std::deque<T>>& fifo,
           std::unique_ptr<T>& tmp)
{
#ifdef THREAD
  std::lock_guard<std::mutex> lock(mtx);
#endif
  fifo->push_front(std::move(tmp));
}

template <typename T>
inline void push_front(const std::shared_ptr<std::deque<T>>& fifo, const T& tmp)
{
#ifdef THREAD
  std::lock_guard<std::mutex> lock(mtx);
#endif
  fifo->push_front(tmp);
}

template <typename T>
inline void
push_back(const std::shared_ptr<std::deque<std::unique_ptr<T>>>& fifo,
          std::unique_ptr<T>& tmp)
{
#ifdef THREAD
  std::lock_guard<std::mutex> lock(mtx);
#endif
  fifo->push_back(std::move(tmp));
}

template <typename T1, typename T2>
inline void
push_back(const std::shared_ptr<std::deque<std::pair<std::unique_ptr<T1>, std::unique_ptr<T2>>>>& fifo,
          std::pair<std::unique_ptr<T1>, std::unique_ptr<T2>>& tmp)
{
#ifdef THREAD
  std::lock_guard<std::mutex> lock(mtx);
#endif
  fifo->push_back(std::move(tmp));
}

template <typename T>
inline void push_back(const std::shared_ptr<std::deque<T>>& fifo, const T& tmp)
{
#ifdef THREAD
  std::lock_guard<std::mutex> lock(mtx);
#endif
  fifo->push_back(tmp);
}

#endif
