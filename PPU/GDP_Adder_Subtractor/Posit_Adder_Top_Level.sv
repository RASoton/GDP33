/////////////////////////////////////////////////////////////////////
// Design unit: Posit Adder top level module
//            :
// File name  : Posit_Adder_Top_Level.sv
//            :
// Description: Parameterized Posit Adder/Subtractor 
//            :
// Limitations: 
//            : 
// System     : SystemVerilog IEEE 1800-2005
//            :
// Author     : Xiaoan He (Jasper)
//            : xh2g20@soton.ac.uk
//
// Revision   : Version 1.3 24/03/2023
/////////////////////////////////////////////////////////////////////

module Optimised_PA #(parameter N = 32, parameter ES = 2, parameter RS = $clog2(N)) 
(
    input logic[N-1:0] IN1, IN2,
    output logic [N-1:0] OUT
);

                                        //////////                  BITS    EXTRACTION                  //////////
logic Sign1, Sign2;
logic signed [RS:0] k1,k2;
logic [ES-1:0] Exponent1, Exponent2;
logic [N-1:0] Mantissa1, Mantissa2;
logic signed [N-2:0] InRemain1, InRemain2;
logic inf1,inf2,zero1,zero2;

Data_Extraction #(.N(N), .ES(ES)) Extract_IN1 (.In(IN1), .Sign(Sign1), .k(k1), .Exponent(Exponent1), .Mantissa(Mantissa1), .InRemain(InRemain1), .inf(inf1), .zero(zero1));
Data_Extraction #(.N(N), .ES(ES)) Extract_IN2 (.In(IN2), .Sign(Sign2), .k(k2), .Exponent(Exponent2), .Mantissa(Mantissa2), .InRemain(InRemain2), .inf(inf2), .zero(zero2));

                                        //////////                  ADDITION ARITHMETIC                  //////////
logic signed [ES+RS:0] LE_O;
logic [ES-1:0] E_O;
logic [N:0] Add_Mant;
logic [N-1:0] Add_Mant_N;
logic signed [RS:0] R_O;
logic LS;

Add_Subtract #(.N(N), .ES(ES)) Add_Sub(.*);

                                        //////////                  ROUNDING                  //////////
Rounding #(.N(N), .ES(ES)) Round(.*);
endmodule