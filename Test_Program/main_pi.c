#include <stdio.h>
#include <stdlib.h>

union posit {
    float f;
    unsigned int i;
};

union posit pi, ONE, P_100;

int main(int argc, char *argv[])
{
  pi.i = 0x4c90fdaa; // value of Pi = 3.141592651605606
  ONE.i = 0x40000000; // value 1 in posit format
  P_100.f = 0x6a400000; // value 100 in posit
  printf("---------------- Posit custom function start ----------------\n");
  
  union posit temp;
  union posit sum, count;
  
  sum.i = 0x00000000; // initial sum to 0
  temp.i = 0x40000000;
  count.i = 0x00000000;
  
  for(int i = 0;; i++)
  {
    sum.f += ONE.f/(P_100.f*count.f + pi.f);
    
    count.f += ONE.f;
    
    if(temp.f != sum.f)
    {
      temp.f = sum.f;
      printf("[%d], %08x \n", i, sum.i);
      continue;
    }
    else
    {
      printf("[%d], %08x, value save finish calulation), i, sum.i");
      break;
    }
    

  }

  printf("----------------- Posit custom function end -----------------\n");

  return EXIT_SUCCESS;
}
