// Reference:
//  http://csclab.murraystate.edu/~bob.pilgrim/445/munkres.html

#include <limits>

#include "hungarian.hpp"
#include "wrapper.hpp"

namespace _internal {

Hungarian::Hungarian(const std::vector<std::vector<float>>& cost)
  : cost(cost)
{
  rows = cost.size();
  cols = cost[0].size();

  row_cover.resize(rows, 0);
  col_cover.resize(cols, 0);

  mask.resize(rows);
  for (auto& mask_line : mask)
    mask_line.resize(cols, 0);

  path.resize(rows+cols+1);
  for (auto& path_line : path)
    path_line.resize(2, 0);
}

Hungarian::~Hungarian()
{
}

// For each row of the cost matrix, find the smallest element and subtract
// it from every element in its row.  When finished, Go to Step 2.
void Hungarian::step_one()
{
  for (int r = 0; r < rows; ++r) {
    float min_in_row = cost[r][0];
    for (int c = 0; c < cols; ++c)
      if (cost[r][c] < min_in_row)
        min_in_row = cost[r][c];

    for (int c = 0; c < cols; ++c)
      cost[r][c] -= min_in_row;
  }

  step = 2;
}

// Find a zero (Z) in the resulting matrix.  If there is no starred
// zero in its row or column, star Z. Repeat for each element in the
// matrix. Go to Step 3.
void Hungarian::step_two()
{
  for (int r = 0; r < rows; ++r) {
    for (int c = 0; c < cols; ++c) {
      if (cost[r][c] == 0 && row_cover[r] == 0 && col_cover[c] == 0) {
        mask[r][c] = 1;
        row_cover[r] = 1;
        col_cover[c] = 1;
      }
    }
  }

  for (int r = 0; r < rows; ++r)
    row_cover[r] = 0;
  for (int c = 0; c < cols; ++c)
    col_cover[c] = 0;

  step = 3;
}

// Cover each column containing a starred zero.  If K columns are covered,
// the starred zeros describe a complete set of unique assignments.  In this
// case, Go to DONE, otherwise, Go to Step 4.
void Hungarian::step_three()
{
  for (int r = 0; r < rows; ++r)
    for (int c = 0; c < cols; ++c)
      if (mask[r][c] == 1)
        col_cover[c] = 1;

  int colcount = 0;
  for (int c = 0; c < cols; ++c)
    if (col_cover[c] == 1)
      colcount += 1;

  if (colcount >= cols || colcount >=rows)
    step = 7;
  else
    step = 4;
}

// methods to support step 4
void Hungarian::find_a_zero(int& row, int& col)
{
  int r = 0;
  int c;
  bool done;
  row = -1;
  col = -1;
  done = false;
  while (!done) {
    c = 0;
    while (true) {
      if (cost[r][c] == 0 && row_cover[r] == 0 && col_cover[c] == 0) {
        row = r;
        col = c;
        done = true;
      }
      c += 1;
      if (c >= cols || done)
        break;
    }
    r += 1;
    if (r >= rows)
      done = true;
  }
}

bool Hungarian::star_in_row(int row)
{
  bool tmp = false;
  for (int c = 0; c < cols; ++c)
    if (mask[row][c] == 1)
      tmp = true;

  return tmp;
}

void Hungarian::find_star_in_row(int row, int& col)
{
  col = -1;
  for (int c = 0; c < cols; ++c)
    if (mask[row][c] == 1)
      col = c;
}

// Find a noncovered zero and prime it.  If there is no starred zero
// in the row containing this primed zero, Go to Step 5.  Otherwise,
// cover this row and uncover the column containing the starred zero.
// Continue in this manner until there are no uncovered zeros left.
// Save the smallest uncovered value and Go to Step 6.
void Hungarian::step_four()
{
  int row = -1;
  int col = -1;
  bool done;

  done = false;
  while (!done) {
    find_a_zero(row, col);
    if (row == -1) {
      done = true;
      step = 6;
    }
    else {
      mask[row][col] = 2;
      if (star_in_row(row)) {
        find_star_in_row(row, col);
        row_cover[row] = 1;
        col_cover[col] = 0;
      }
      else {
        done = true;
        step = 5;
        path_row_0 = row;
        path_col_0 = col;
      }
    }
  }
}

// methods to support step 5
void Hungarian::find_star_in_col(int c, int& r)
{
  r = -1;
  for (int i = 0; i < rows; ++i)
    if (mask[i][c] == 1)
      r = i;
}

void Hungarian::find_prime_in_row(int r, int& c)
{
  for (int j = 0; j < cols; ++j)
    if (mask[r][j] == 2)
      c = j;
}

void Hungarian::augment_path()
{
  for (int p = 0; p < path_count; ++p)
    if (mask[path[p][0]][path[p][1]] == 1)
      mask[path[p][0]][path[p][1]] = 0;
    else
      mask[path[p][0]][path[p][1]] = 1;
}

void Hungarian::clear_covers()
{
  for (int r = 0; r < rows; ++r)
    row_cover[r] = 0;
  for (int c = 0; c < cols; ++c)
    col_cover[c] = 0;
}

void Hungarian::erase_primes()
{
  for (int r = 0; r < rows; ++r)
    for (int c = 0; c < cols; ++c)
      if (mask[r][c] == 2)
        mask[r][c] = 0;
}

// Construct a series of alternating primed and starred zeros as follows.
// Let Z0 represent the uncovered primed zero found in Step 4.  Let Z1 denote
// the starred zero in the column of Z0 (if any). Let Z2 denote the primed zero
// in the row of Z1 (there will always be one).  Continue until the series
// terminates at a primed zero that has no starred zero in its column.
// Unstar each starred zero of the series, star each primed zero of the series,
// erase all primes and uncover every line in the matrix.  Return to Step 3.
void Hungarian::step_five()
{
  bool done;
  int r = -1;
  int c = -1;

  path_count = 1;
  path[path_count - 1][0] = path_row_0;
  path[path_count - 1][1] = path_col_0;
  done = false;
  while (!done) {
    find_star_in_col(path[path_count - 1][1], r);
    if (r > -1) {
      path_count += 1;
      path[path_count - 1][0] = r;
      path[path_count - 1][1] = path[path_count - 2][1];
    }
    else
        done = true;
    if (!done) {
      find_prime_in_row(path[path_count - 1][0], c);
      path_count += 1;
      path[path_count - 1][0] = path[path_count - 2][0];
      path[path_count - 1][1] = c;
    }
  }
  augment_path();
  clear_covers();
  erase_primes();
  step = 3;
}

// methods to support step 6
void Hungarian::find_smallest(float& minval)
{
  for (int r = 0; r < rows; ++r)
    for (int c = 0; c < cols; ++c)
      if (row_cover[r] == 0 && col_cover[c] == 0)
        if (minval > cost[r][c])
          minval = cost[r][c];
}

// Add the value found in Step 4 to every element of each covered row, and subtract
// it from every element of each uncovered column. Return to Step 4 without
// altering any stars, primes, or covered lines.
void Hungarian::step_six()
{
  float minval = std::numeric_limits<float>::max();
  find_smallest(minval);
  for (int r = 0; r < rows; ++r) {
    for (int c = 0; c < cols; ++c) {
      if (row_cover[r] == 1)
        cost[r][c] += minval;
      if (col_cover[c] == 0)
        cost[r][c] -= minval;
    }
  }
  step = 4;
}

void Hungarian::solve()
{
  step = 1;

  bool done = false;
  while (!done) {
    switch (step) {
      case 1:
        step_one();
        break;
      case 2:
        step_two();
        break;
      case 3:
        step_three();
        break;
      case 4:
        step_four();
        break;
      case 5:
        step_five();
        break;
      case 6:
        step_six();
        break;
      case 7:
        done = true;
        break;
    }
  }
}

std::pair<std::vector<int>, std::vector<int>>
Hungarian::dump()
{
  std::vector<int> row_idx, col_idx;

  for (int r = 0; r < rows; ++r) {
    for (int c = 0; c < cols; ++c) {
      if (mask[r][c] == 1) {
        row_idx.emplace_back(r);
        col_idx.emplace_back(c);
      }
    }
  }

  return std::make_pair(row_idx, col_idx);
}

}

std::pair<std::vector<int>, std::vector<int>>
linear_sum_assignment(const std::vector<std::vector<float>>& cost)
{
  if (cost.size() == 0 || cost[0].size() == 0)
    return std::make_pair(std::vector<int>{}, std::vector<int>{});

#if 0
  printf("cost.size: %d\n", static_cast<int>(cost.size()));
  for (auto x : cost) {
    for (auto y : x) {
      printf("%6.3f\t", y);
    }
    printf("\n");
  }
#endif

  _internal::Hungarian solver(cost);
  solver.solve();
  return solver.dump();
}
