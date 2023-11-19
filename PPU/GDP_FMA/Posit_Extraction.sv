/////////////////////////////////////////////////////////////////////
// Design unit: DataExtraction
//            :
// File name  : Posit_Extraction.sv
//            :
// Description: Extracting posit element from n bits binary number
//            :
// Limitations: None
//            : 
// System     : SystemVerilog IEEE 1800-2005
//            :
// Author     : Xiaoan He (Jasper)
//            : xh2g20@ecs.soton.ac.uk
//
// Revision   : Version 1.0 22/11/2022
/////////////////////////////////////////////////////////////////////

module Data_Extraction #( parameter N = 8, parameter ES = 3, parameter RS = $clog2(N))
(
    input logic signed [N-1:0] In,
    output logic signed Sign,
    output logic signed [RS+2:0] k,
    output logic [ES-1:0] Exponent,
    output logic [N-1:0] Mantissa,
    output logic signed [N-2:0] InRemain,
    output logic inf,
    output logic zero
);

logic zero_check;
logic RegimeCheck; 
logic signed [RS:0] EndPosition;
logic signed [N-2:0] ShiftedRemain;
// 8 bits - 1-bit hidden 1, N-ES-2 bit mant from ShiftedRemain, and compensate zeros afterwards
logic [(N-1)-1-(N-ES-2)-1:0] ZEROs= '0;
// logic [(N-ES+2)-1-(N-ES-2)-1:0] ZERO = '0;
int i;
Leading_Bit_Detector #(.N(N), .ES(ES)) LBD1 (.*);

always_comb
begin
    //infinity & zero check;
    zero_check = |In[N-2:0];
    inf = In[N-1] & (~zero_check);
    zero = ~(In[N-1] | zero_check);

    // Sign Bit Extraction
    Sign = In[N-1];

    // if sign bit is 1, then 2's compliment
    if (Sign)
        InRemain = -In[N-2:0];
    else   
        InRemain = In[N-2:0];


    // Regime Bits Extraction
    /*
     There is a Leading_Bit_Detector defined before the always_comb block 
     which takes the input without sign bit as module input and outputs 
     EndPosition of Regime Bits and RegimeCheck which is the 1st bit of Regime bits
    */
    if(RegimeCheck)
        k = EndPosition - 1'b1;
    else 
        k = -EndPosition;
    //Exponent Bits Extraction
    ShiftedRemain = InRemain << (EndPosition + 1'b1 );
    Exponent = ShiftedRemain[N-2:((N-1)-ES)];

    //Mantissa Bits Extraction
    Mantissa = {1'b1, ShiftedRemain[N-ES-2:0], ZEROs};
end
endmodule