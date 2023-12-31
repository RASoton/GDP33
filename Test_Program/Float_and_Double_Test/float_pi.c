#include <stdio.h>
#include <stdlib.h>

int main(int argc, char *argv[])
{
  float pi = 3.141592653589793238462643383279502884197f; // value of Pi = 3.141592651605606
  float ONE = 1.0f; // value 1 in posit format
  float P_100 = 100.0f; // value 100 in posit
  printf("---------------- Float custom function start ----------------\n");
  
  float temp;
  float sum, count;
  
  sum = 0.0f; // initial sum to 0
  temp = 1.0f;
  count = 0.0f;
  
  int i = 0;
  
  for(i;; i++)
  {
    sum += ONE/(P_100*count + pi);
    
    count += ONE;
    
    if(temp != sum)
    {
      temp = sum;
      printf("[%d], %.30f \n", i, sum);
      continue;
    }
    else
    {
      printf("[%d], %.30f, value same finish calulation \n", i, sum);
      break;
    }
  }
  
  for(i; i>=0; i--)
  {
    sum -= ONE/(P_100*(count) + pi);
    count -= ONE;
    printf("[%d], %.30f \n", i, sum);
  }
  
  

  printf("----------------- Float custom function end -----------------\n");

  return 0;
}
