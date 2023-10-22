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

module Rounding2_2 #(parameter N = 32, parameter ES = 2, parameter RS = $clog2(N)) 
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
    // output logic [3:0] rounding_map
);

logic [(N+ES+N+3)-1:0] tmp_o;
logic [(N+N+ES+N+3)-1:0]sft_tmp_o;
logic check;
// logic L,G,R,S,ulp;
logic [N-1:0] rnd_ulp; 
logic [N:0] sft_tmp_o_rnd_ulp;
logic [N-1:0] sft_tmp_o_rnd;
logic [N-1:0] sft_tmp_oN;
// Letian Chen 
logic round, L, G, G2, R, S, round_overflow, round_condition;
logic [2*N-1:0] regime_temp_output; // store regime and sign
logic [N-1:0] regime_output;
logic [N-1:0] exp_frac_output, exp_frac_output1, exp_frac_temp_output;
logic [N+1:0] exp_frac_combine_output, rounding_temp, rounding_temp1, rounding_temp2;
logic [N-1:0] temp_output, temp_output1;
logic [1:0] overflow_shift;

always_comb
begin
    //////      ROUNDING        //////
    exp_frac_combine_output = {1'b0,E_O[ES-1:0],Add_Mant_N[N-2:0]}; // combine 1-Overflow bit, 2-Exponent bit, 31-fraction bit
    // Do rounding Here
    // rounding_temp = exp_frac_combine_output << (N-R_O+1);
    rounding_temp = exp_frac_combine_output << (N-R_O-2);
    rounding_temp1 = rounding_temp >> (N-R_O+1);
    // rounding_temp1 = rounding_temp;
    L = rounding_temp[N+1];
    G = rounding_temp[N];
    G2 = |rounding_temp[N:0];
    R = rounding_temp[N-1];
    S = |rounding_temp[N-1:0];
    // rounding_map = {L,G,R,S};
    rounding_temp2 = exp_frac_combine_output >> R_O;
    
    // if(G==1'b0)
    // round = 1'b0;
    // else if(L==1'b0 && G==1'b1)
    // round = 1'b0;
    // else
    // round = 1'b1;
    // round = (G&(R|S)) | (L&G&(~(R|S)));
    // round = (~L&~G&~S)|(~L&~G&~R)|(~R&~S)|(L&G&R);
    // ---------- Banker's Rounding
    // if(G2 == 1'b1 && L == 1'b1)
    // round = 1;
    // else if(S == 1'b1 && L == 1'b0)
    // round = 1;
    // else if(R&S ==1'b1 && L == 1'b1)
    // round = 1;
    // else
    // round = 0;
    // ---------- round half to even
    round_condition = G;
    if(round_condition)
    begin
        if(S)
        round = 1'b1;
        else
        round = L;
    end
    else
    round = '0;
    // Finish Rounding
    
    // Pick usefull bit from rounded object
    exp_frac_temp_output = exp_frac_combine_output[N+1:2] + (R_O+1);
    round_overflow = exp_frac_temp_output[N-1];
    exp_frac_output1 = exp_frac_combine_output[N+1:2] >> (R_O+1); // Shift the Exponent bit and Fration bit to mach the regime and sign region
    exp_frac_output = exp_frac_output1;
    // round_overflow = exp_frac_temp_output[N-1];
    // overflow_shift = {round_overflow, 0};

    // Handle Regime
    if(LE_O[ES+RS]) // When the exponents is 
    regime_temp_output = 1 << (2*N-R_O-2);
    else // When the exponents is 
    regime_temp_output = ~(1) << (2*N-R_O-2);

    regime_output = regime_temp_output[2*N-1:N];
    regime_output[N-1] = 1'b0; // Keep 1st bit of the output = 0 before handle sign

    temp_output1 = (regime_output | exp_frac_output) + round; // conbine regime + exponent_fraction

    // Change the Sign of the final result
    if(LS)
    temp_output = -temp_output1;
    else
    temp_output = temp_output1;


    // //  N bits 0 or 1, following a terminating bit, exponent bits, (N-ES-1) bits mantissa, 3 bits for rounding
    // tmp_o = { {N{~LE_O[ES+RS]}}, LE_O[ES+RS], E_O, Add_Mant_N[N-2:0], 3'b0 };
    // sft_tmp_o = {tmp_o, {N{1'b0}}};
    // sft_tmp_o = sft_tmp_o >> R_O;

    // L = sft_tmp_o[N+4+(N-(N-ES))]; 
    // G = sft_tmp_o[N+3+(N-(N-ES))]; // Guard bit
    // R = sft_tmp_o[N+2+(N-(N-ES))]; // round bit
    // S = |sft_tmp_o[N+1+(N-(N-ES)):0];  // sticky bit
    // // ulp = ((G & (R | S)) | (L & G & ~(R | S)));
    // ulp = ((G & (R | S)) | (L & G & ~(R)));
    

    // rnd_ulp= {{N-1{1'b0}},ulp};

    
    // sft_tmp_o_rnd_ulp = sft_tmp_o[2*N-1+3+(N-(N-ES)):N+3+(N-(N-ES))] + rnd_ulp - (~S&G&~R);

    // if ((R_O < N-ES-2))
    //     sft_tmp_o_rnd = sft_tmp_o_rnd_ulp[N-1:0];
    // else
    //     sft_tmp_o_rnd = sft_tmp_o[2*N-1+3+(N-(N-ES)):N+3+(N-(N-ES))];
    
    // if(LS)
    //     sft_tmp_oN = -sft_tmp_o_rnd;
    // else
    //     sft_tmp_oN = sft_tmp_o_rnd+1;


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
        OUT = {N{1'b0}};
    else
        // OUT = {LS, sft_tmp_oN[N-1:1]};
        OUT = temp_output;
end
endmodule