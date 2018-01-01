#include <algorithm>
#include <cassert>
#include <iostream>
#include <iomanip>
#include <random>
#include <tuple>

#include "hungarian.hpp"

bool test_hungarian()
{
  const int rows = 6;
  const int cols = 8;

  std::vector<std::vector<float>> cost;
  cost.resize(rows);
  for (auto& cost_line : cost)
    cost_line.resize(cols);

  std::mt19937 rand(42);
  for (int i = 0; i < rows; ++i)
    for (int j = 0; j < cols; ++j)
      cost[i][j] = static_cast<float>(rand() % 1024);

  std::vector<int> row_idx, col_idx;
  std::tie(row_idx, col_idx) = linear_sum_assignment(cost);

  for (int i = 0; i < row_idx.size(); ++i)
    std::cout << row_idx[i] << " " << col_idx[i] << std::endl;
  std::cout << std::endl;

  std::cout << "\t";
  for (int j = 0; j < cols; ++j) {
    auto iter = std::find(col_idx.begin(), col_idx.end(), j);
    auto idx = std::distance(col_idx.begin(), iter);
    if (iter != col_idx.end())
      std::cout << std::setw(4) << row_idx[idx] << " ";
    else
      std::cout << std::setw(4) << "_" << " ";
  }
  std::cout << std::endl;
  for (int i = 0; i < rows; ++i) {
    auto iter = std::find(row_idx.begin(), row_idx.end(), i);
    auto idx = std::distance(row_idx.begin(), iter);
    if (iter != row_idx.end())
      std::cout << std::setw(4) << col_idx[idx] << "\t";
    else
      std::cout << std::setw(4) << "_" << "\t";
    for (int j = 0; j < cols; ++j)
      std::cout << std::setw(4) << cost[i][j] << " ";
    std::cout << std::endl;
  }

  return true;
}

int main(void)
{
  assert(test_hungarian());

  return 0;
}
