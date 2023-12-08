/////////////////////////////////////////////////////////////////////
// Design unit: Posit Multiplication Arithmetic
//            :
// File name  : Mult_Arithmetic.sv
//            :
// Description:
//            :
// Limitations:
//            :
// System     : SystemVerilog IEEE 1800-2005
//            :
// Author     : Xiaoan(Jasper) He   Letian(Brian) Chen
//            : xh2g20@soton.ac.uk  lc1e20@soton.ac.uk
//
// Revision   : Version 1.2 24/10/2023
/////////////////////////////////////////////////////////////////////
timeunit 1ns;
timeprecision 1ps;
module Mult #(parameter N = 32, parameter ES = 2, parameter RS = $clog2(N))
  (
    input  logic signed Sign1, Sign2,
    input  logic signed [RS:0] k1,k2,
    input  logic [ES-1:0] Exponent1, Exponent2,
    input  logic [N-1:0] Mantissa1, Mantissa2,
    input  logic signed [N-2:0] InRemain1, InRemain2,
    input  logic inf1, inf2,
    input  logic zero1, zero2,
    output logic [2*N-1:0] Mult_Mant_N,
    output logic [ES-1:0] E_O,
    output logic signed [RS+2:0] R_O, sumR,
    output logic inf, zero, Sign
  );
  int i;
  logic [2*N-1:0] Mult_Mant;
  logic signed [1:0]sumE_Ovf;
  logic [ES:0] sumE;  // 1 more bit then Exponent for Ovf

  always_comb
  begin
    //  check infinity and zero
    inf = inf1 | inf2;
    zero = zero1 | zero2;

    //////      MULTIPLICATION ARITHMETIC       //////
    Sign = Sign1 ^ Sign2;

    //  Mantissa Multiplication Handling
    Mult_Mant = Mantissa1 * Mantissa2;

    if(Mult_Mant[2*N-1])
    Mult_Mant_N = Mult_Mant;
    else
    Mult_Mant_N = Mult_Mant << 1;

    if(sumR[RS+2])
    sumE = Exponent1+Exponent2 + Mult_Mant[2*N-1];
    else
    sumE = Exponent1+Exponent2 + Mult_Mant[2*N-1];


    sumE_Ovf = {1'b0, sumE[ES]};
    sumR = k1+k2+sumE_Ovf;

    if(sumR[RS+2]) // negtaive exponent
    begin
      E_O = sumE[ES-1:0];
      R_O = -sumR;
    end
    else            // psotive exponent
    begin
      E_O = sumE[ES-1:0];
      R_O = sumR + 1'b1;
    end
  end
endmodule
