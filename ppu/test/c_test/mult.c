
#include <stdio.h>
#include <stdlib.h>

union PositBinary {
    float f;
    unsigned int i;
};

void printPositBinary(float num) {
    union PositBinary fb;
    fb.f = num;

    //printf("Floating-point number: %f\n", fb.f);
    printf("Binary representation: %08x\n", fb.i);
}

int main(int argc, char *argv[])
{
  printf("---------------- Posit custom function start ----------------\n");
  // custom code here
   volatile unsigned int test_a[5] = {0x40000000, 0x45882244, 0x12556763, 0x99383658, 0x94586527};
   volatile unsigned int test_b[5] = {0x48000000, 0x91277305, 0x22625129, 0x45645234, 0x45216378};
   volatile unsigned int test_result[5] = {0x48000000, 0x8f1ae70e, 0xa0e25ec, 0x965328a5, 0x91b7d8ea};
  
  union PositBinary a_temp, b_temp, r_temp, comp_temp;
  
  int error_count = 0;
  for(int i = 0; i < 5; i++)
  {
    a_temp.i = test_a[i];
    b_temp.i = test_b[i];
    comp_temp.i = test_result[i];
    r_temp.f = a_temp.f * b_temp.f;
    printPositBinary(r_temp.f);
    
    if(r_temp.f == comp_temp.f)
    {
      printf("compare successful\n");
    }
    else
    {
      error_count += 1;
      printf("compare fail\n");
    }
  }
  printf("----------------- Posit custom function end -----------------\n");

  return EXIT_SUCCESS;
}
