#include <stdio.h>
#include <limits.h>

#include "util.h"
#include "kinpira.h"
#include "types.h"



void print_result(s16 *output, const int length)
{
  int number  = -1;
  int max     = INT_MIN;

  for (int i = 0; i < length; i++) {
    printf("%d: %d\n", i, output[i]);

    if (max < output[i]) {
      number = i;
      max    = output[i];
    }
  }

  printf("the answer is %d.\n", number);
}



void print_port()
{
  printf(
    "&port[0]:  %08x &port[1]:  %08x &port[2]:  %08x &port[3]:  %08x\n"
    "&port[4]:  %08x &port[5]:  %08x &port[6]:  %08x &port[7]:  %08x\n"
    "&port[8]:  %08x &port[9]:  %08x &port[10]: %08x &port[11]: %08x\n"
    "&port[12]: %08x &port[13]: %08x &port[14]: %08x &port[15]: %08x\n"
    "&port[16]: %08x &port[17]: %08x &port[18]: %08x &port[19]: %08x\n"
    "&port[20]: %08x &port[21]: %08x &port[22]: %08x &port[23]: %08x\n"
    "&port[24]: %08x &port[25]: %08x &port[26]: %08x &port[27]: %08x\n"
    "&port[28]: %08x &port[29]: %08x &port[30]: %08x &port[31]: %08x\n"
    , port[0], port[1], port[2], port[3]
    , port[4], port[5], port[6], port[7]
    , port[8], port[9], port[10], port[11]
    , port[12], port[13], port[14], port[15]
    , port[16], port[17], port[18], port[19]
    , port[20], port[21], port[22], port[23]
    , port[24], port[25], port[26], port[27]
    , port[28], port[29], port[30], port[31]
  );
}

