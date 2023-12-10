/*
 * Copyright 2020 ETH Zurich
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <stdio.h>
#include <stdlib.h>

union FloatBinary {
    float f;
    unsigned int i;
};

void printFloatBinary(float num) {
    union FloatBinary fb;
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
  
  union FloatBinary a_temp, b_temp, r_temp, comp_temp;
  
//  volatile float a = 0.23;
//  volatile float b = 0.13;
//  volatile float output;
  
//  volatile float temp = 0x4800000;
//  volatile float temp2 = 0x4800000;
  //temp.i = 0x48000000;
  
//  output = a * b;
//  printFloatBinary(output);
//  printf("\n");

  int error_count = 0;
  for(int i = 0; i < 5; i++)
  {
    a_temp.i = test_a[i];
    b_temp.i = test_b[i];
    comp_temp.i = test_result[i];
    r_temp.f = a_temp.f * b_temp.f;
    printFloatBinary(r_temp.f);
    
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
