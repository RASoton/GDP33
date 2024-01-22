
#include <stdio.h>
#include <stdlib.h>
#include "randomValue.h"

union FloatBinary {
    float f;
    unsigned int i;
};

int main(int argc, char *argv[])
{

  union FloatBinary one, two, four;
  union FloatBinary a_temp, b_temp, inside_circle, iter, result;
  
  inside_circle.i = 0;
  iter.i = 0x73e80000; // 1000 in posit
  one.i = 0x40000000;  // 1 in posit
  two.i = 0x48000000;  // 2 in posit
  four.i = 0x50000000; // 4 in posit
  
  unsigned iterations = 1000;
  for (unsigned int i = 0; i < iterations; i += 2) { 
    a_temp.i = randomValues[i];
    b_temp.i = randomValues[i + 1];
    printf("Iteration=%d\n", i);
    if (a_temp.f * a_temp.f + b_temp.f * b_temp.f <= one.f)
      inside_circle.f = inside_circle.f + one.f;
  }
    printf("x: %08x\n", inside_circle.i);
    result.f =  four.f * inside_circle.f / (iter.f / two.f);
    printf("Estimated Pi: %08x\n", result.i);
  
  return EXIT_SUCCESS;
}
