#ifndef _HUNGARIAN_HPP_
#define _HUNGARIAN_HPP_

#include <vector>

namespace _internal {

class Hungarian {
public:
  Hungarian(std::vector<std::vector<float>> cost);
  ~Hungarian();

  void step_one();
  void step_two();
  void step_three();
  void step_four();
  void step_five();
  void step_six();

  void solve();
  std::pair<std::vector<int>, std::vector<int>> dump();

private:
  void find_a_zero(int& row, int& col);
  bool star_in_row(int row);
  void find_star_in_row(int row, int& col);
  void find_star_in_col(int c, int& r);
  void find_prime_in_row(int r, int& c);
  void augment_path();
  void clear_covers();
  void erase_primes();
  void find_smallest(float& minval);

  int rows;
  int cols;
  int path_count;
  int path_row_0;
  int path_col_0;
  int step;

  std::vector<int> row_cover;
  std::vector<int> col_cover;
  std::vector<std::vector<float>> cost;
  std::vector<std::vector<int>> mask;
  std::vector<std::vector<int>> path;
};

}

std::pair<std::vector<int>, std::vector<int>>
linear_sum_assignment(std::vector<std::vector<float>> &cost);

#endif
