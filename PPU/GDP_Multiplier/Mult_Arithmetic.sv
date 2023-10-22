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
// Author     : Xiaoan(Jasper) He 
//            : xh2g20@soton.ac.uk
//
// Revision   : Version 1.1 21/02/2023
/////////////////////////////////////////////////////////////////////
timeunit 1ns; timeprecision 1ps;
module Mult #(parameter N = 8, parameter ES = 4, parameter RS = $clog2(N)) 
(
    input  logic signed Sign1, Sign2,
    input  logic signed [RS+1:0] k1,k2,
    input  logic [ES-1:0] Exponent1, Exponent2,
    input  logic [N-1:0] Mantissa1, Mantissa2,
    input  logic signed [N-2:0] InRemain1, InRemain2,
    input  logic inf1, inf2,
    input  logic zero1, zero2,
    output logic [2*N-1:0] Mult_Mant_N,
    output logic [RS+ES+1:0]Total_EO,
    output logic [ES-1:0] E_O,
    output logic signed [RS:0] R_O,
    output logic inf, zero, Operation
);

logic [2*N-1:0] Mult_Mant;
logic Mant_mult_Ovf;
logic [RS+ES+1:0] Total_EON;

always_comb
begin
    //  check infinity and zero
    inf = inf1 | inf2;
	zero = zero1 | zero2;

    //////      MULTIPLICATION ARITHMETIC       //////
     
    Operation = Sign1 ^ Sign2;
    //  Mantissa Multiplication Handling
    Mult_Mant = Mantissa1 * Mantissa2;
    Mant_mult_Ovf = Mult_Mant[2*N-1];   
    Mult_Mant_N = Mant_mult_Ovf ? Mult_Mant : (Mult_Mant << 1);

    //  Exponent Handling
    /*
        for multiplication, the total exponent is the sum of 
        the respective total exponent of each input
    */
    Total_EO = {k1,Exponent1} + {k2, Exponent2} + Mant_mult_Ovf; 

    Total_EON =  Total_EO[RS+ES+1] ? (-Total_EO) : Total_EO;

    E_O = Total_EO[ES-1:0];

    R_O = (~Total_EO[ES+RS+1'b1] || |(Total_EON[ES-1:0])) ? Total_EON[ES+RS:ES] + 1'b1 : Total_EON[ES+RS:ES];
end
endmodule