/////////////////////////////////////////////////////////////////////
// Design unit: Rounding
//            :
// File name  : Rounding.sv
//            :
// Description: Round to nearest representable value
//            :
// Limitations: 
//            : 
// System     : SystemVerilog IEEE 1800-2005
//            :
// Author     : Xiaoan He (Jasper)
//            : xh2g20@soton.ac.uk
//
// Revision   : Version 1.3 23/03/2023
/////////////////////////////////////////////////////////////////////

module Rounding #(parameter N = 32, parameter ES = 2, parameter RS = $clog2(N)) 
(
    input  logic[N-1:0] IN1, IN2,
    input  logic signed [ES+RS:0] LE_O,
    input  logic [ES-1:0] E_O,
    input  logic [N:0] Add_Mant,
    input  logic [N-1:0] Add_Mant_N,
    input  logic signed [RS:0] R_O,
    input  logic LS,
    input  logic inf1, inf2,
    input  logic zero1, zero2,
    output logic [N-1:0] OUT
);

logic [(N+ES+N+3)-1:0] tmp_o;
logic [(N+N+ES+N+3)-1:0]sft_tmp_o;
logic L,G,R,S,ulp;
logic [N-1:0] rnd_ulp; 
logic [N:0] sft_tmp_o_rnd_ulp;
logic [N-1:0] sft_tmp_o_rnd;
logic [N-1:0] sft_tmp_oN;

always_comb
begin
    //////      ROUNDING        //////

    //  N bits 0 or 1, following a terminating bit, exponent bits, (N-ES-1) bits mantissa, 3 bits for rounding
    tmp_o = { {N{~LE_O[ES+RS]}}, LE_O[ES+RS], E_O, Add_Mant_N[N-2:0], 3'b0 };
    sft_tmp_o = {tmp_o, {N{1'b0}}};
    sft_tmp_o = sft_tmp_o >> R_O;

    L = sft_tmp_o[N+4+(N-(N-ES))]; 
    G = sft_tmp_o[N+3+(N-(N-ES))]; // Guard bit
    R = sft_tmp_o[N+2+(N-(N-ES))]; // round bit
    S = |sft_tmp_o[N+1+(N-(N-ES)):0];  // sticky bit
    ulp = ((G & (R | S)) | (L & G & ~(R | S)));
    
    rnd_ulp= {{N-1{1'b0}},ulp};

    
    sft_tmp_o_rnd_ulp = sft_tmp_o[2*N-1+3+(N-(N-ES)):N+3+(N-(N-ES))] + rnd_ulp;

    if ((R_O < N-ES-2))
        sft_tmp_o_rnd = sft_tmp_o_rnd_ulp[N-1:0];
    else
        sft_tmp_o_rnd = sft_tmp_o[2*N-1+3+(N-(N-ES)):N+3+(N-(N-ES))];
    
    if(LS)
        sft_tmp_oN = -sft_tmp_o_rnd;
    else
        sft_tmp_oN = sft_tmp_o_rnd;


    //////      FINAL OUTPUT        //////

    if (zero1)
        OUT = IN2;
    else if (zero2) 
        OUT = IN1;
    else if (inf1)          
        OUT = IN1;
    else if (inf2)             
        OUT = IN2;
    else if (IN1 == -IN2)
        OUT = {(N-1){1'b0}};
    else
        OUT = {LS, sft_tmp_oN[N-1:1]};
end
endmodule