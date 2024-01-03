/////////////////////////////////////////////////////////////////////
// Design unit: Rounding
//            :
// File name  : Rounding.sv
//            :
// Description: Round to nearest even value
//            :
// Limitations: 
//            : 
// System     : SystemVerilog IEEE 1800-2005
//            :
// Author     : Letian(Brian) Chen
//            : lc1e20
//
// Revision   : Version 1.0 10/2023
//            : Version 1.1 10/2023 2N bits
/////////////////////////////////////////////////////////////////////

module Rounding #(parameter N = 32, parameter ES = 2, parameter RS = $clog2(N)) 
(
    input  logic [N-1:0] IN1, IN2,
    input  logic signed[RS+ES+1:0]LE_O,
    input  logic [ES-1:0] E_O,
    input  logic [2*N-1:0] FMA_Mant_N,
    input  logic signed [RS+2:0] R_O,
    input  logic Sign,
    input  logic inf, zero,
    output logic [N-1:0] OUT
    // output logic [3:0] rounding_map
);

// Letian Chen 
logic round, L, G, G2, R, S, round_overflow, round_condition;
logic [2*N-1:0] regime_temp_output; // store regime and sign
logic [N-1:0] regime_output;
logic [N-1:0] exp_frac_output, exp_frac_output1, exp_frac_temp_output;
logic [2*N+1:0] exp_frac_combine_output, rounding_temp, rounding_temp1, rounding_temp2;
logic [N-1:0] temp_output, temp_output1;
logic [1:0] overflow_shift;
logic [N-1:0] OUT_neg;
logic signed [RS+4:0] R_O_fin;

always_comb
begin
    //////      ROUNDING        //////
    exp_frac_combine_output = {1'b0,E_O[ES-1:0],FMA_Mant_N[2*N-2:0]}; // combine 1-bit Overflow , 2-bit Exponent , 31-bit fraction 
   
    // Do rounding Here
    rounding_temp = exp_frac_combine_output << (N-R_O-2);
    L = rounding_temp[2*N+1]; // last frac bit
    G = rounding_temp[2*N];   // bit after
    // G2 = |rounding_temp[N:0];
    // R = rounding_temp[N-1];
    S = |rounding_temp[2*N-1:0];  // btis remaining
    // ---------- round half to even

    if(R_O>31)
    round_condition = 0;
    else
    round_condition = 1;

    //  set the limit of max R_O
    if(R_O > 31 && ~LE_O[RS+ES+1]) // when regime sequence w/0
      R_O_fin = 31;
    else if(R_O > 30 && LE_O[RS+ES+1]) // when regime sequence w/1
      R_O_fin = 30;
    else
      R_O_fin = R_O;

    if(G & round_condition)
    begin
        if(S)
        round = 1'b1;
        else
        round = L;
    end
    else
    round = '0;
    
    // Pick usefull bit from rounded object
    // exp_frac_temp_output = exp_frac_combine_output[2*N+1:N+2] + (R_O_fin+1);
    // round_overflow = exp_frac_temp_output[N-1];
    exp_frac_output1 = exp_frac_combine_output[2*N+1:N+2] >> (R_O_fin+1); // Shift the Exponent bit and Fration bit to match the regime and sign region
    // exp_frac_output = exp_frac_output1;
    // round_overflow = exp_frac_temp_output[N-1];
    // overflow_shift = {round_overflow, 0};

    // Handle Regime
    if(LE_O[RS+ES+1]) // exponent -ve
    regime_temp_output = 1 << (2*N-R_O_fin-2);
    else // exponent +ve
    regime_temp_output = ~(1) << (2*N-R_O_fin-2);

    regime_output = regime_temp_output[2*N-1:N];
    regime_output[N-1] = 1'b0; // Keep MSB of output = 0 before handle sign

    temp_output1 = (regime_output | exp_frac_output1) + round; // combine regime + exponent_fraction

    // Handle Sign
    if(Sign)
    temp_output = -temp_output1;
    else
    temp_output = temp_output1;
    
    // Output
    if(zero|inf)
    OUT = {inf,{N-1{1'b0}}};
    else
    OUT = temp_output;
    OUT_neg = -OUT;

end
endmodule