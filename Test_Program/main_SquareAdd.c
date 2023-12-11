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

void print_float_binary(float num) {
    union FloatBinary fb;
    fb.f = num;

    //printf("Floating-point number: %f\n", fb.f);
    printf("%08x\n", fb.i);
}

int main(int argc, char *argv[])
{
  printf("---------------- Posit custom function start ----------------\n");
  
  union FloatBinary ONE, ZERO;
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
