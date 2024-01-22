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
#include "testcase.h"

union PositBinary {
    float f;
    unsigned int i;
};

int main(int argc, char *argv[])
{

  union PositBinary a_temp, b_temp, c_temp, result;

  // Test for Addition
  printf("---------------- Posit Addition Start ---------------\n");
  for (int i = 0; i < 200; i++) {
      a_temp.i = test_a[i];
      b_temp.i = test_b[i];
      result.f = a_temp.f + b_temp.f;
      printf("%08x + %08x = %08x\n", a_temp.i, b_temp.i, result.i);
  }
  printf("---------------- Posit Addition End ----------------\n");
  
  printf("---------------- Posit Subtraction Start ----------------\n");
  // Test for Subtraction
  for (int i = 0; i < 200; i++) {
      a_temp.i = test_a[i];
      b_temp.i = test_b[i];
      result.f = a_temp.f - b_temp.f;
      printf("%08x - %08x = %08x\n", a_temp.i, b_temp.i, result.i);
  }
  printf("---------------- Posit Subtraction End ----------------\n");
  
  printf("---------------- Posit Multiplication Start ----------------\n");
  // Test for Multiplication
  for (int i = 0; i < 200; i++) {
      a_temp.i = test_a[i];
      b_temp.i = test_b[i];
      result.f = a_temp.f * b_temp.f;
      printf("%08x * %08x = %08x\n", a_temp.i, b_temp.i, result.i);
  }
  printf("---------------- Posit Multiplication End ----------------\n");

  printf("---------------- Posit Division Start ----------------\n");
  // Test for Division
  for (int i = 0; i < 200; i++) {
      a_temp.i = test_a[i];
      b_temp.i = test_b[i];
      result.f = a_temp.f / b_temp.f;
      printf("%08x / %08x = %08x\n", a_temp.i, b_temp.i, result.i);
  }
  printf("---------------- Posit Division End ----------------\n");

  // RISC-V specific operations
  printf("---------------- Posit FMADD Start ----------------\n");
  // FMADD
  for (int i = 0; i < 200; i++) {
      a_temp.i = test_a[i];
      b_temp.i = test_b[i];
      c_temp.i = test_a[(i+1)%200]; 
      __asm__ ("fmadd.s %0, %1, %2, %3" : "=f" (result.f) : "f" (a_temp.f), "f" (b_temp.f), "f" (c_temp.f));
      printf("%08x * %08x + %08x = %08x\n", a_temp.i, b_temp.i, c_temp.i, result.i);
  }
  printf("---------------- Posit FMADD End ----------------\n");

  printf("---------------- Posit FMSUB Start ----------------\n");
  // FMSUB
  for (int i = 0; i < 200; i++) {
      a_temp.i = test_a[i];
      b_temp.i = test_b[i];
      c_temp.i = test_a[(i+1)%200]; 
      __asm__ ("fmsub.s %0, %1, %2, %3" : "=f" (result.f) : "f" (a_temp.f), "f" (b_temp.f), "f" (c_temp.f));
      printf("%08x * %08x - %08x = %08x\n", a_temp.i, b_temp.i, c_temp.i, result.i);
  }
  printf("---------------- Posit FMSUB End ----------------\n");
  
  printf("---------------- Posit FNMADD Start ----------------\n");
  // FNMADD
  for (int i = 0; i < 200; i++) {
      a_temp.i = test_a[i];
      b_temp.i = test_b[i];
      c_temp.i = test_a[(i+1)%200]; 
      __asm__ ("fnmadd.s %0, %1, %2, %3" : "=f" (result.f) : "f" (a_temp.f), "f" (b_temp.f), "f" (c_temp.f));
      printf("-%08x * %08x - %08x = %08x\n", a_temp.i, b_temp.i, c_temp.i, result.i);
  }
  printf("---------------- Posit FNMADD End ----------------\n");
  
  printf("---------------- Posit FNMSUB Start ----------------\n");
  // FNMSUB
  for (int i = 0; i < 200; i++) {
      a_temp.i = test_a[i];
      b_temp.i = test_b[i];
      c_temp.i = test_a[(i+1)%200]; 
      __asm__ ("fnmsub.s %0, %1, %2, %3" : "=f" (result.f) : "f" (a_temp.f), "f" (b_temp.f), "f" (c_temp.f));
      printf("-%08x * %08x + %08x = %08x\n", a_temp.i, b_temp.i, c_temp.i, result.i);
  }
  printf("---------------- Posit FNMSUB End ----------------\n");
 
  printf("---------------- Posit FSQRT Start ----------------\n");
  // FSQRT
  for (int i = 0; i < 200; i++) {
      a_temp.i = test_a[i];
      __asm__ ("fsqrt.s %0, %1" : "=f" (result.f) : "f" (a_temp.f));
      printf("Square root of %08x = %08x\n", a_temp.i, result.i);
  }
  printf("---------------- Posit FSQRT End ----------------\n");
  
  return EXIT_SUCCESS;
}
