#include <stdio.h>
#include <stdlib.h>

const double pi = 3.1415926535897932384626433832795028841971693993751058209749445923078164062862089986280348253421170679f; // value of Pi
const double ONE = 1.0f;                                                                                                  // value 1 in posit format
const double P_100 = 100.0f;                                                                                              // value 100 in posit

int main(int argc, char *argv[])
{
  printf("---------------- Double custom function start ----------------\n");

  double temp, temp_count;
  volatile double sum, count, mid_value;

  sum = 0.0f; // initial sum to 0
  temp;
  count = 0.0f;
  temp_count = 0x78331115;

  int i = 0;
  for (i; i < 10000000; i++) // the Posit stops at 8380000. using double to run to 10000000
  {
    mid_value = ONE / (P_100 * count + pi);
    if (temp_count != count)
    {
      sum += mid_value;
    }

    if (temp_count == count)
    {
      printf("[%d - %.40f], %.40f, %.40f Value of n is equal to previous n. Program finish\n", i, temp, sum, mid_value);
      break;
    }
    else if (temp != sum)
    {
      if (i % 5000 == 0)
      {
        printf("[%d - %.40f], %.40f, %.40f \n", i, count, sum, mid_value);
      }
    }
    else if (temp == sum)
    {
      printf("[%d - %.40f], %.40f, %.40f, value same finish calulation \n", i, count, sum, mid_value);
      break;
    }
    else
    {
      printf("error \n");
    }
    temp = sum;
    temp_count = count;
    count += ONE;
  }
  i--;
  count -= 1;
  for (i; i >= 0; i--)
  {
    sum -= ONE / (P_100 * count + pi);
    count -= ONE;
    //    printf("[%d], %.40f \n", i, sum);
  }
  printf("[%d], %.40f \n", i, sum);
  printf("Finish reverse calculation.");

  printf("----------------- Double custom function end -----------------\n");

  return 0;
}
