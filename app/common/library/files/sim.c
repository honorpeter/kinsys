#include <stdio.h>
#include <stdlib.h>
#include <limits.h>
#include <assert.h>

#include "kinpira.h"
#include "sim.h"

static u32 bit(u32 value, int high, int low)
{
  return value << (BWIDTH-1-high) >> (BWIDTH-1-high) >> low;
}

static inline s16 mlt(unsigned N, s16 a, s16 b)
{
  int c = a * b;

  if (c < 0)
    return (c >> N) - 1;
  else
    return (c >> N);
}

#if 0
static s16** init_2(int a, int b)
{ // {{{
  s16** x;

  x = (s16**)calloc(a, sizeof(s16*));
  for (int i = 0; i < a; ++i) {
    x[i] = (s16*)calloc(b, sizeof(s16));
  }

  return x;
} // }}}
#endif

static s16*** init_3(int a, int b, int c)
{ // {{{
  s16*** x;

  x = (s16***)calloc(a, sizeof(s16**));
  for (int i = 0; i < a; ++i) {
    x[i] = (s16**)calloc(b, sizeof(s16*));
    for (int j = 0; j < b; ++j) {
      x[i][j] = (s16*)calloc(c, sizeof(s16));
    }
  }

  return x;
} // }}}

#if 0
static s16**** init_4(int a, int b, int c, int d)
{ // {{{
  s16**** x;

  x = (s16****)calloc(a, sizeof(s16***));
  for (int i = 0; i < a; ++i) {
    x[i] = (s16***)calloc(b, sizeof(s16**));
    for (int j = 0; j < b; ++j) {
      x[i][j] = (s16**)calloc(c, sizeof(s16*));
      for (int k = 0; k < c; ++k) {
        x[i][j][k] = (s16*)calloc(d, sizeof(s16));
      }
    }
  }

  return x;
} // }}}
#endif

#if 0
static void kill_2(s16*** x, int a, int b)
{ // {{{
  assert(b);

  for (int i = 0; i < a; ++i) {
    free(x[i]);
  }
  free(x);
} // }}}
#endif

static void kill_3(s16*** x, int a, int b, int c)
{ // {{{
  assert(c);

  for (int i = 0; i < a; ++i) {
    for (int j = 0; j < b; ++j) {
      free(x[i][j]);
    }
    free(x[i]);
  }
  free(x);
} // }}}

#if 0
static void kill_4(s16**** x, int a, int b, int c, int d)
{ // {{{
  assert(d);

  for (int i = 0; i < a; ++i) {
    for (int j = 0; j < b; ++j) {
      for (int k = 0; k < c; ++k) {
        free(x[i][j][k]);
      }
      free(x[i][j]);
    }
    free(x[i]);
  }
  free(x);
} // }}}
#endif

static void conv()
{
  const int N = *reg_qbits;

  const int n_out = bit(*reg_base_param0, 2*LWIDTH-1, LWIDTH);
  const int n_in  = bit(*reg_base_param0, LWIDTH-1, 0);
  const int img_h = bit(*reg_base_param1, 2*LWIDTH-1, LWIDTH);
  const int img_w = bit(*reg_base_param1, LWIDTH-1, 0);
  const int fea_h = bit(*reg_base_param2, 2*LWIDTH-1, LWIDTH);
  const int fea_w = bit(*reg_base_param2, LWIDTH-1, 0);

  const int kern  = bit(*reg_conv_param0, LWIDTH-1, 0);
  const int strid = bit(*reg_conv_param1, 2*LWIDTH-1, LWIDTH);
  const int pad   = bit(*reg_conv_param1, LWIDTH-1, 0);

  s16 (*input)[img_h][img_w]
    = (s16 (*)[img_h][img_w])((UINTPTR)mem_image + *reg_in_offset);
  s16 (*output)[fea_h][fea_w]
    = (s16 (*)[fea_h][fea_w])((UINTPTR)mem_image + *reg_out_offset);

  s16 weight[n_out][n_in][kern][kern];
  for (int n = 0; n < n_out; ++n) {
    int which = (n % RENKON_CORE);
    int addr  = (n / RENKON_CORE) * (n_in*kern*kern + 1) + *reg_net_offset;
    for (int m = 0; m < n_in; ++m)
      for (int k = 0; k < kern; ++k)
        for (int l = 0; l < kern; ++l)
#ifdef __KPR_QUANT__
          weight[n][m][k][l] = *reg_w_scale * mem_renkon[which][addr++]
                             + *reg_w_offset;
#else
          weight[n][m][k][l] = mem_renkon[which][addr++];
#endif
  }

  s16*** padded = init_3(n_in, img_h+2*pad, img_w+2*pad);
  for (int m = 0; m < n_in; ++m)
    for (int i = 0; i < img_h; ++i)
      for (int j = 0; j < img_w; ++j)
        padded[m][i+pad][j+pad] = input[m][i][j];

  for (int n = 0; n < n_out; ++n) {
    for (int i = 0; i < img_h+2*pad-kern+1; i+=strid) {
      for (int j = 0; j < img_w+2*pad-kern+1; j+=strid) {
        s16 acc = 0;
        for (int m = 0; m < n_in; ++m)
          for (int k = 0; k < kern; ++k)
            for (int l = 0; l < kern; ++l)
              acc += mlt(N, weight[n][m][k][l], padded[m][i+k][j+l]);
        output[n][i/strid][j/strid] = acc;
      }
    }
  }
  kill_3(padded, n_in, img_h+2*pad, img_w+2*pad);
}

void bias_renkon()
{
  const int n_out = bit(*reg_base_param0, 2*LWIDTH-1, LWIDTH);
  const int n_in  = bit(*reg_base_param0, LWIDTH-1, 0);
  const int fea_h = bit(*reg_base_param2, 2*LWIDTH-1, LWIDTH);
  const int fea_w = bit(*reg_base_param2, LWIDTH-1, 0);

  const int kern  = bit(*reg_conv_param0, LWIDTH-1, 0);

  s16 (*input)[fea_h][fea_w]
    = (s16 (*)[fea_h][fea_w])((UINTPTR)mem_image + *reg_out_offset);
  s16 (*output)[fea_h][fea_w]
    = (s16 (*)[fea_h][fea_w])((UINTPTR)mem_image + *reg_out_offset);

  s16 bias[n_out];
  for (int n = 0; n < n_out; ++n) {
    int which = (n % RENKON_CORE);
    int addr  = (n / RENKON_CORE) * (n_in*kern*kern + 1) + *reg_net_offset;
#ifdef __KPR_QUANT__
    bias[n] = *reg_b_scale * mem_renkon[which][addr+n_in*kern*kern]
            + *reg_b_offset;
#else
    bias[n] = mem_renkon[which][addr+n_in*kern*kern];
#endif
  }

  for (int n = 0; n < n_out; ++n)
    for (int i = 0; i < fea_h; ++i)
      for (int j = 0; j < fea_w; ++j)
        output[n][i][j] = input[n][i][j] + bias[n];
}

static void relu_renkon()
{
  const int n_out = bit(*reg_base_param0, 2*LWIDTH-1, LWIDTH);
  const int fea_h = bit(*reg_base_param2, 2*LWIDTH-1, LWIDTH);
  const int fea_w = bit(*reg_base_param2, LWIDTH-1, 0);

  s16 (*input)[fea_h][fea_w]
    = (s16 (*)[fea_h][fea_w])((UINTPTR)mem_image + *reg_out_offset);
  s16 (*output)[fea_h][fea_w]
    = (s16 (*)[fea_h][fea_w])((UINTPTR)mem_image + *reg_out_offset);

  for (int n = 0; n < n_out; ++n)
    for (int i = 0; i < fea_h; ++i)
      for (int j = 0; j < fea_w; ++j)
        if (input[n][i][j] < 0) output[n][i][j] = 0;
}

static void pool()
{
  const int n_out = bit(*reg_base_param0, 2*LWIDTH-1, LWIDTH);
  const int fea_h = bit(*reg_base_param2, 2*LWIDTH-1, LWIDTH);
  const int fea_w = bit(*reg_base_param2, LWIDTH-1, 0);

  const int kern  = bit(*reg_pool_param0, LWIDTH-1, 0);
  const int strid = bit(*reg_pool_param1, 2*LWIDTH-1, LWIDTH);
  const int pad   = bit(*reg_pool_param1, LWIDTH-1, 0);

  const int out_h = (fea_h + 2*pad + strid - kern)/strid;
  const int out_w = (fea_w + 2*pad + strid - kern)/strid;

  s16 (*input)[fea_h][fea_w]
    = (s16 (*)[fea_h][fea_w])((UINTPTR)mem_image + *reg_out_offset);
  s16 (*output)[out_h][out_w]
    = (s16 (*)[out_h][out_w])((UINTPTR)mem_image + *reg_out_offset);

  s16*** padded = init_3(n_out, fea_h+2*pad+strid-1, fea_w+2*pad+strid-1);
  for (int m = 0; m < n_out; ++m)
    for (int i = 0; i < fea_h; ++i)
      for (int j = 0; j < fea_w; ++j)
        padded[m][i+pad][j+pad] = input[m][i][j];

  for (int n = 0; n < n_out; ++n) {
    for (int i = 0; i < fea_h+2*pad+strid-kern; i+=strid) {
      for (int j = 0; j < fea_w+2*pad+strid-kern; j+=strid) {
        s16 max = SHRT_MIN;
        for (int k = 0; k < kern; ++k)
          for (int l = 0; l < kern; ++l)
            if (padded[n][i+k][j+l] > max) max = padded[n][i+k][j+l];
        output[n][i/strid][j/strid] = max;
      }
    }
  }
  kill_3(padded, n_out, fea_h+2*pad+strid-1, fea_w+2*pad+strid-1);
}

static void full()
{
  const int N = *reg_qbits;

  const int n_out = bit(*reg_base_param0, 2*LWIDTH-1, LWIDTH);
  const int n_in  = bit(*reg_base_param0, LWIDTH-1, 0);

  s16 *input = (s16 *)((UINTPTR)mem_image + *reg_in_offset);
  s16 *output = (s16 *)((UINTPTR)mem_image + *reg_out_offset);

  s16 weight[n_out][n_in];
  for (int n = 0; n < n_out; ++n) {
    int which = (n % GOBOU_CORE);
    int addr  = (n / GOBOU_CORE) * (n_in + 1) + *reg_net_offset;
    for (int m = 0; m < n_in; ++m)
#ifdef __KPR_QUANT__
      weight[n][m] = *reg_w_scale * mem_gobou[which][addr++]
                   + *reg_w_offset;
#else
      weight[n][m] = mem_gobou[which][addr++];
#endif
  }

  for (int n = 0; n < n_out; ++n) {
    s16 acc = 0;
    for (int m = 0; m < n_in; ++m)
      acc += mlt(N, weight[n][m], input[m]);
    output[n] = acc;
  }
}

void bias_gobou()
{
  const int n_out = bit(*reg_base_param0, 2*LWIDTH-1, LWIDTH);
  const int n_in  = bit(*reg_base_param0, LWIDTH-1, 0);

  s16 *input = (s16 *)((UINTPTR)mem_image + *reg_out_offset);
  s16 *output = (s16 *)((UINTPTR)mem_image + *reg_out_offset);

  s16 bias[n_out];
  for (int n = 0; n < n_out; ++n) {
    const int which = (n % GOBOU_CORE);
    const int addr  = (n / GOBOU_CORE) * (n_in + 1) + *reg_net_offset;
#ifdef __KPR_QUANT__
    bias[n] = *reg_b_scale * mem_gobou[which][addr+n_in]
            + *reg_b_offset;
#else
    bias[n] = mem_gobou[which][addr+n_in];
#endif
  }

  for (int n = 0; n < n_out; ++n)
    output[n] = input[n] + bias[n];
}

#if 0
static void norm_gobou()
{
}
#endif

static void relu_gobou()
{
  const int n_out = bit(*reg_base_param0, 2*LWIDTH-1, LWIDTH);

  s16 *input = (s16 *)((UINTPTR)mem_image + *reg_out_offset);
  s16 *output = (s16 *)((UINTPTR)mem_image + *reg_out_offset);

  for (int n = 0; n < n_out; ++n)
    if (input[n] < 0) output[n] = 0;
}

void sim_renkon()
{
  const int bias_en = bit(*reg_bias_param, BWIDTH-1, BWIDTH-1);
  const int relu_en = bit(*reg_actv_param, BWIDTH-1, BWIDTH-1);
  const int pool_en = bit(*reg_pool_param0, BWIDTH-1, BWIDTH-1);

  conv();
  if (bias_en)
    bias_renkon();
  // if (norm_en)
  //   norm_renkon();
  if (relu_en)
    relu_renkon();
  if (pool_en)
    pool();
}

void sim_gobou()
{
  const int bias_en = bit(*reg_bias_param, BWIDTH-1, BWIDTH-1);
  const int relu_en = bit(*reg_actv_param, BWIDTH-1, BWIDTH-1);

  full();
  if (bias_en)
    bias_gobou();
  // if (norm_en)
  //   norm_gobou();
  if (relu_en)
    relu_gobou();
}
