
#include <stdio.h>
#include <stdlib.h>

union PositBinary {
    float f;
    unsigned int i;
};

void print_float_binary(float num) {
    union PositBinary fb;
    fb.f = num;

    //printf("Floating-point number: %f\n", fb.f);
    printf("%08x\n", fb.i);
}

int main(int argc, char *argv[])
{
  printf("---------------- Posit custom function start ----------------\n");
  
  union PositBinary ONE, ZERO;
  ONE.i = 0x40000000;
  ZERO.i = 0x00000000;

  // custom code here
  volatile float sum = ZERO.f; // Initial sum = 0
  volatile float denom = ONE.f; // denom = 1
  volatile float count = ONE.f; // initial count = 1
  
  for (int i = 0; i < 100; i++)
  {
    sum += ONE.f/denom;
    count = count + ONE.f;
    denom = count*count;
    
    printf("[%d] sum = ", i);
    print_float_binary(sum);
    
  }


  printf("----------------- Posit custom function end -----------------\n");

  return EXIT_SUCCESS;
}
