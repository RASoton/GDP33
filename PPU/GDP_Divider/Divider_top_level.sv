/////////////////////////////////////////////////////////////////////
// Design unit: Optimised Posit Adder top level module
//            :
// File name  : Optimised_Adder_top_level.sv
//            :
// Description: Parameterized Posit Adder/Subtractor
//            : with larger intermediate register for rounding 
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

module Divider #(parameter N = 32, parameter ES = 4, parameter RS = $clog2(N)) 
(
    input logic[N-1:0] IN1, IN2,
    output logic signed[N-1:0] OUT
);

                                        //////////                  BITS    EXTRACTION                  //////////
logic signed Sign1, Sign2;
logic signed [RS:0] k1,k2;
logic [ES-1:0] Exponent1, Exponent2;
logic [N-1:0] Mantissa1, Mantissa2;
logic signed [N-2:0] InRemain1, InRemain2;
logic inf1,inf2,zero1,zero2;

Data_Extraction #(.N(N), .ES(ES)) Extract_IN1 (.In(IN1), .Sign(Sign1), .k(k1), .Exponent(Exponent1), .Mantissa(Mantissa1), .InRemain(InRemain1), .inf(inf1), .zero(zero1));
Data_Extraction #(.N(N), .ES(ES)) Extract_IN2 (.In(IN2), .Sign(Sign2), .k(k2), .Exponent(Exponent2), .Mantissa(Mantissa2), .InRemain(InRemain2), .inf(inf2), .zero(zero2));

                                        //////////                  ADDITION ARITHMETIC                  //////////                        
logic [2*N-1:0] Div_Mant_N;
logic [RS+ES+1:0]Total_EO, Total_EON;
logic [ES-1:0] E_O;
logic signed [RS+2:0] R_O,sumR;
logic inf, zero, Sign;

Div #(.N(N), .ES(ES)) Divide(.*);
                                        //////////                  ROUNDING                  //////////
Rounding2_2 #(.N(N), .ES(ES)) Round(.*);
endmodule