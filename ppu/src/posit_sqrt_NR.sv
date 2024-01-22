// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

// Language: SystemVerilog
// Description: posit-based non-restoring square root

module posit_sqrt_NR #(
  parameter posit_pkg::posit_format_e   pFormat = posit_pkg::posit_format_e'(0),
  localparam int unsigned N  = posit_pkg::posit_width(pFormat), 
  localparam int unsigned ES = posit_pkg::exp_bits(pFormat), 
  localparam int unsigned RS = $clog2(N)
) (
  input logic Enable,
  input logic signed Sign,
  input logic signed [RS:0] Regime,
  input logic [ES-1:0] Exponent,
  input logic [N-1:0] Mantissa,     
  output logic [ES-1:0] E_O,
  output logic signed [RS+4:0] R_O,
  output logic [2*N-1:0] Sqrt_Mant,
  output logic sign_Exponent_O
);
  logic [2*N-1:0] D;
  logic [2*N-1:0] Q;
  logic signed [N+1:0] R;
  logic signed [RS:0] Sqrt_regime;

  always_comb begin
    R_O = '0;
    E_O = '0;
    Sqrt_Mant = '0;
    if (Enable) begin 
      // square root of regime
      Sqrt_regime = Regime >>> 1; 
      // square root of exponent
      E_O = (Regime & 1'b1) ? ((Exponent >> 1) + 2) : (Exponent >> 1); 
      // Non-restoring square root algorithm
      Q = '0; // quotient or root
      R = '0; // remainder
      // extend the input to 64-bit for higher precision
      // also multiply mantissa by 2 if exponent is odd
      D = (Exponent & 1'b1) ? (Mantissa << N) : (Mantissa << N-1); 
      // need to make this part modular for multiple clock cycles
      // to replace the for loop
      for (int i=N-1; i>=0; i--) begin
        R = (R << 2) | ((D >> (i+i)) & 3'b11);
        R = (R >= 0) ? (R-((Q << 2) | 2'b01)) : (R+((Q << 2) | 2'b11));
        Q = (R >= 0) ? ((Q <<1 ) | 1'b1) : ((Q << 1) | 1'b0);
      end
        R = (R < 0) ? (R+((Q << 1) | 1'b1)) : R;
        Sqrt_Mant = Q << 32;
        // adjust for rounding
        sign_Exponent_O = Sqrt_regime[RS];
        R_O = (sign_Exponent_O) ? -Sqrt_regime : Sqrt_regime+1;
    end
  end
endmodule