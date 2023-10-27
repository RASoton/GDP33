/////////////////////////////////////////////////////////////////////
// Design unit: Posit Division Arithmetic
//            :
// File name  : DIV_Arithmetic.sv
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
// Revision   : Version 1.0 25/10/2023
/////////////////////////////////////////////////////////////////////
timeunit 1ns; timeprecision 1ps;
module Div #(parameter N = 8, parameter ES = 4, parameter RS = $clog2(N))
  (
    input  logic signed Sign1, Sign2,
    input  logic signed [N-2:0] InRemain1, InRemain2,
    input  logic signed [RS:0] k1,k2,
    input  logic [ES-1:0] Exponent1, Exponent2,
    input  logic [N-1:0] Mantissa1, Mantissa2,
    input  logic inf1, inf2,
    input  logic zero1, zero2,
    output logic [2*N-1:0] Div_Mant_N,
    output logic [ES-1:0] E_O,
    output logic signed [RS+2:0] R_O, sumR,
    output logic inf, zero, Sign
  );
  int i;
  logic [2*N-1:0] Div_Mant;
  logic [2*N-1:0] dividend, divisor; //被除数, 除数
  logic signed [1:0]sumE_Ovf;
  logic [ES:0] sumE;  // 1 more bit then Exponent for Ovf

  always_comb
  begin
    //  check infinity and zero
    inf = inf1 | inf2;
    zero = zero1 | zero2;

    //////      DivIPLICATION ARITHMETIC       //////
    Sign = Sign1 ^ Sign2;
    // dividend = {Mantissa1, {N-1{0}}};
    dividend = Mantissa1 << N;
    divisor = Mantissa2;
    //  Mantissa Diviplication Handling
    Div_Mant = dividend / divisor;

    if(Div_Mant[2*N-1])
    Div_Mant_N = Div_Mant;
    else
    Div_Mant_N = Div_Mant << 1;

    if(sumR[RS+2])
    sumE = Exponent1-Exponent2 + Div_Mant[2*N-1];
    else
    sumE = Exponent1-Exponent2 + Div_Mant[2*N-1];


    sumE_Ovf = {1'b0, sumE[ES]};
    sumR = k1-k2+sumE_Ovf;

    if(sumR[RS+2]) // negative exponent
    begin
      E_O = sumE[ES-1:0];
      R_O = -sumR;
    end
    else            // positive exponent
    begin
      E_O = sumE[ES-1:0];
      R_O = sumR + 1;
    end
  end
endmodule
