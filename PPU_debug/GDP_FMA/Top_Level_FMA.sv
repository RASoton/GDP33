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

module FMA #(parameter N = 32, parameter ES = 2, parameter RS = $clog2(N)) 
(
    input logic[N-1:0] IN1, IN2, IN3,
    input logic op_N, // op_N=1 --> Fused Neg operation; op_N=0 --> Fused operation
    input logic op_sub, // op_sub=1 --> Sub operation; op_sub=0 --> Add operation
    output logic [N-1:0] OUT
);

                                        //////////                  BITS    EXTRACTION                  //////////
logic signed Sign1, Sign2, Sign3;
logic signed [RS+2:0] k1, k2, k3;
logic [ES-1:0] Exponent1, Exponent2, Exponent3;
logic [N-1:0] Mantissa1, Mantissa2, Mantissa3;
logic signed [N-2:0] InRemain1, InRemain2, InRemain3;
logic inf1,inf2,zero1,zero2, inf3, zero3;

Data_Extraction #(.N(N), .ES(ES)) Extract_IN1 (.In(IN1), .Sign(Sign1), .k(k1), .Exponent(Exponent1), .Mantissa(Mantissa1), .InRemain(InRemain1), .inf(inf1), .zero(zero1));
Data_Extraction #(.N(N), .ES(ES)) Extract_IN2 (.In(IN2), .Sign(Sign2), .k(k2), .Exponent(Exponent2), .Mantissa(Mantissa2), .InRemain(InRemain2), .inf(inf2), .zero(zero2));
Data_Extraction #(.N(N), .ES(ES)) Extract_IN3 (.In(IN3), .Sign(Sign3), .k(k3), .Exponent(Exponent3), .Mantissa(Mantissa3), .InRemain(InRemain3), .inf(inf3), .zero(zero3));

                                        //////////                  ADDITION ARITHMETIC                  //////////                        
logic [2*N-1:0] FMA_Mant_N;
logic [RS+ES+1:0]LE_O;
logic [ES-1:0] E_O;
logic signed [RS+2:0] R_O,sumR;
logic inf, zero, Sign;

Arithmetic_FMA #(.N(N), .ES(ES)) FMA(.*);
                                        //////////                  ROUNDING                  //////////
Rounding #(.N(N), .ES(ES)) Round(.*);
endmodule