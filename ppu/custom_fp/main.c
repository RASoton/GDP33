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
#include <math.h>

//void matmulNxN(float* matA, float* matB, float* matC, int N);

#define N 5

//float matA[N*N], matB[N*N];
//float matC[N*N], matC_ref[N*N];
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

//void activate_random_stall(void)
//{
//  // Address vector for rnd_stall_reg, to control memory stalls/interrupt
//  volatile unsigned int *rnd_stall_reg[16];
//
//  // Setup the address vector
//  rnd_stall_reg[0] = 0x16000000;
//  for (int i = 1; i < 16; i++) {
//    rnd_stall_reg[i] = rnd_stall_reg[i-1] + 1; // It is a pointer to int ("+ 1" means "the next int")
//  }
//
//  /* The interposition of the stall generator between CPU and MEM should happen BEFORE the stall generetor is active */
//  // Interpose the stall generator between CPU and D-MEM (rnd_stall_reg[1])
//  *rnd_stall_reg[1] = 0x01;
//  // Interpose the stall generator between CPU and I-MEM (rnd_stall_reg[0])
//  *rnd_stall_reg[0] = 0x01;
//
//  // DATA MEMORY
//  // Set max n. stalls on both GNT and VALID for RANDOM mode (rnd_stall_reg[5])
//  *rnd_stall_reg[5] = 0x05;
//  // Set n. stalls on  GNT (rnd_stall_reg[7])
//  *rnd_stall_reg[7] = 0x05;
//  // Set n. stalls on VALID (rnd_stall_reg[9])
//  *rnd_stall_reg[9] = 0x05;
//
//  // INSTRUCTION MEMORY
//  // Set max n. stalls on both GNT and VALID for RANDOM mode (rnd_stall_reg[4])
//  *rnd_stall_reg[4] = 0x05;
//  // Set n. stalls on  GNT (rnd_stall_reg[6])
//  *rnd_stall_reg[6] = 0x05;
//  // Set n. stalls on VALID (rnd_stall_reg[8])
//  *rnd_stall_reg[8] = 0x05;
//
//  /* Activating stalls on D and I Mem has to be done as last operation. Do not change the order. */
//  // Set stall mode on D-MEM (off=0, standard=1, random=2) (rnd_stall_reg[3])
//  *rnd_stall_reg[3] = 0x02;
//  // Set stall mode on I-MEM (off=0, standard=1, random=2) (rnd_stall_reg[2])
//  *rnd_stall_reg[2] = 0x02;
//}

int main(int argc, char *argv[])
{
  printf("---------------- Posit custom function start ----------------\n");
  // custom code here
  volatile unsigned int test_a[5] = {0x40000000, 0x45882244, 0x12556763, 0x99383658, 0x94586527};
  volatile unsigned int test_b[5] = {0x48000000, 0x91277305, 0x22625129, 0x45645234, 0x45216378};

  union FloatBinary a_temp, b_temp;

  volatile float a = 0.23;
  volatile float b = 0.13;
  volatile float output;

//  output = a * b;
//  printf("a * b = %x \n", output);
//  printf("binary = ");

//  printFloatBinary(output);
//  printf("\n");
  for(int i = 0; i < 5; i++)
  {
    a_temp.i = test_a[i];
    b_temp.i = test_b[i];
    printFloatBinary(a_temp.f * b_temp.f);
  }
  printf("----------------- Posit custom function end -----------------\n");

  return EXIT_SUCCESS;
}
