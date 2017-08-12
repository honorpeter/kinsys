#ifndef _UTIL_H_
#define _UTIL_H_

#include "types.h"

void assign_map(layer *l, u32 *weight, u32 *bias);
void assign_vec(layer *l, u32 *weight, u32 *bias);

void exec_core(layer *l);

void print_result(s16 *output, const int length);
void print_port();

#endif
