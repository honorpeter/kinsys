#ifndef _KINPIRA_H
#define _KINPIRA_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>

char *layer_type[] = {
  "convolution_2d",
  "max_pooling_2d",
  "batch_normalization",
  "fully_connected",
  "relu",
};

typedef struct {
  char type[32];
  char name[32];
  union {
    struct {
      int16_t shape[4];
      int16_t *data;
    } convolution_2d;

    struct {
      int16_t kernel;
    } max_pooling_2d;

    struct {
      int16_t alpha;
      int16_t beta;
    } batch_normalization;

    struct {
      int16_t shape[2];
      int16_t *data;
    } fully_connected;
  };
} kpr_layer;


#ifdef __cplusplus
}
#endif

#endif
