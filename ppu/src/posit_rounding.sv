// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

// Language: SystemVerilog

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

module posit_rounding #(
  parameter posit_pkg::posit_format_e   pFormat = posit_pkg::posit_format_e'(0),
  localparam int unsigned N = posit_pkg::posit_width(pFormat), 
  localparam int unsigned ES = posit_pkg::exp_bits(pFormat), 
  localparam int unsigned RS = $clog2(N)
) (
  input  logic [ES-1:0] E_O,
  input  logic [2*N-1:0] Comp_Mant_N,
  input  logic signed [RS+4:0] R_O,
  input  logic sign_Exponent_O,
  input  logic Sign,
  input  logic NaR, zero,
  output logic [N-1:0] OUT
  // output logic [3:0] rounding_map
);

  // logic L,G,R,S,ulp;
  // Letian Chen 
  logic round, L, G, S, round_condition;
  logic [2*N-1:0] regime_temp_output; // store regime and sign
  logic [N-1:0] regime_output;
  logic [N-1:0] exp_frac_output;
  logic [2*N+1:0] exp_frac_combine_output, rounding_temp, rounding_temp1;
  logic [N-1:0] temp_output, temp_output1;
  // logic [N-1:0] OUT_neg;
  logic [RS+4:0] R_O_fin;
  
  logic [RS+4:0] usd_ro;
  assign usd_ro = R_O;
  
  always_comb begin
    // exp_frac_combine_output = {3'b1, {temp2}}; // combine 1-Overflow bit, 2-Exponent bit, 63-fraction bit
    //////      ROUNDING        //////
    exp_frac_combine_output = {1'b0,E_O[ES-1:0],Comp_Mant_N[2*N-2:0]}; // combine 1-Overflow bit, 2-Exponent bit, 63-fraction bit
   
    // Do rounding Here
    rounding_temp = exp_frac_combine_output << (N-usd_ro-2);
    L = rounding_temp[2*N+1];
    G = rounding_temp[2*N];
    S = |rounding_temp[2*N-1:0];
    // ---------- round half to even

    if(usd_ro>31)
    round_condition = 0;
    else
    round_condition = 1;

    //  set the limit of max R_O
    if(usd_ro > 31 && ~sign_Exponent_O) // when regime sequence w/0
      R_O_fin = 31;
    else if(usd_ro > 30 && sign_Exponent_O) // when regime sequence w/1
      R_O_fin = 30;
    else
      R_O_fin = usd_ro;

    if(G & round_condition)
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
    exp_frac_output = exp_frac_combine_output[2*N+1:N+2] >> (R_O_fin+1); // Shift the Exponent bit and Fration bit to match the regime and sign regio

    // Handle Regime
    if(sign_Exponent_O) // When the exponents is -ve
    regime_temp_output = 1 << (2*N-R_O_fin-2);
    else // When the exponents is +ve
    regime_temp_output = ~(1) << (2*N-R_O_fin-2);

    regime_output = regime_temp_output[2*N-1:N];
    regime_output[N-1] = 1'b0; // Keep 1st bit of the output = 0 before handle sign

    temp_output1 = (regime_output | exp_frac_output) + round; // conbine regime + exponent_fraction

    // Change the Sign of the final result
    if(Sign)
    temp_output = -temp_output1;
    else
    temp_output = temp_output1;

    if(zero|NaR)
    OUT = {NaR,{N-1{1'b0}}};
    else
    OUT = temp_output;

end
endmodule