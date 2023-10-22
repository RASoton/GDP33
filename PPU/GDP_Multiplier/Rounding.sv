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

module Rounding #(parameter N = 8, parameter ES = 4, parameter RS = $clog2(N)) 
(
    input logic [2*N-1:0] Mult_Mant_N,
    input logic [RS+ES+1:0]Total_EO,
    input logic [ES-1:0] E_O,
    input logic signed [RS:0] R_O,
    input logic inf, zero, Operation,
    output logic signed[N-1:0] OUT
);

logic [(N+ES+2*N+3)-1:0] tmp_o;
logic [(N+N+ES+2*N+3)-1:0] sft_tmp_o;
logic L,G,R,S,ulp;
logic [N-1:0] rnd_ulp; 
logic [N:0] sft_tmp_o_rnd_ulp;
logic [N-1:0] sft_tmp_o_rnd;
logic [N-1:0] sft_tmp_oN;

always_comb
begin
    //////      ROUNDING        //////
    tmp_o = {{N{~Total_EO[ES+RS+1]}}, Total_EO[ES+RS+1], E_O, Mult_Mant_N[2*N-2:0], 3'b0};
    sft_tmp_o = {tmp_o, {N{1'b0}}};

    if (R_O[RS])
        sft_tmp_o = sft_tmp_o >> {RS{1'b1}};
    else
        sft_tmp_o = sft_tmp_o >> R_O; 

    L = sft_tmp_o[N+4 + (N+4)]; 
    G = sft_tmp_o[N+3 + (N+4)]; 
    R = sft_tmp_o[N+2 + (N+4)]; 
    S = |sft_tmp_o[N+1 + (N+4) :0];
    ulp = ((G & (R | S)) | (L & G & ~(R | S)));
    // ulp = ((G & (R | S)) | (L & G & ~(R)));
    rnd_ulp= {{N-1{1'b0}},ulp};


    sft_tmp_o_rnd_ulp = sft_tmp_o[2*N-1+3 + (N+4):N+3+(N+4)] + rnd_ulp;
    // sft_tmp_o_rnd_ulp = sft_tmp_o[2*N-1+3 + (N+4):N+3+(N+4)] + rnd_ulp- (~S&G&~R);

    sft_tmp_o_rnd = (R_O < N-ES-2) ? sft_tmp_o_rnd_ulp[N-1:0] : sft_tmp_o[2*N-1+3+(N+4):N+3+(N+4)];


    //Final Output

    sft_tmp_oN = Operation ? -sft_tmp_o_rnd : sft_tmp_o_rnd;
    OUT = inf|zero ? {inf,{N-1{1'b0}}} : {Operation, sft_tmp_oN[N-1:1]};
    //OUT = {Operation, sft_tmp_oN[N-1:1]};
end
endmodule