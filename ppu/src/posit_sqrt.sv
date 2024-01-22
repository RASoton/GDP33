// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

// Language: SystemVerilog
// Description: Newton-Raphson square root

module posit_sqrt #(
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
  output logic [RS+4:0] R_O,
  output logic [2*N-1:0] Sqrt_Mant,
  output logic sign_Exponent_O
);
  logic signed [RS:0] Sqrt_regime;
  logic [N-1:0] sqrt_x;
  logic [N-1:0] x, index, shift, slope, intercept;
  logic [2*N-1:0] sqr_x, mx;
  logic [3*N-1:0] error;

  localparam logic [31:0] slopes_even [0:7]      = '{32'h3a904440, 32'h318b0307, 32'h2a9f9134, 32'h252d7982, 32'h20cd01d7, 32'h1d386f55, 32'h1a3f5400, 32'h17bf1c04};
  localparam logic [31:0] intercepts_even [0:7]  = '{32'hBA904440, 32'hB06A5AE0, 32'hA7C40C98, 32'hA0472C03, 32'h99B67883, 32'h93E50A6F, 32'h8EB11A9C, 32'h8A00B1A2};
  localparam logic [31:0] slopes_odd [0:7]       = '{32'h29692225, 32'h23083E61, 32'h1E23A4A6, 32'h1A49DEF0, 32'h173194AA, 32'h14A9775B, 32'h128F4851, 32'h10CA945A};
  localparam logic [31:0] intercepts_odd [0:7]   = '{32'h81F5CDDF, 32'h7CBE9B83, 32'h76A0DB59, 32'h71556B7F, 32'h6CB0FC16, 32'h6893CC75, 32'h64E5FA23, 32'h619528B5};
  
  always_comb begin
    if (Enable) begin
      // square root of regime
      Sqrt_regime = Regime >>> 1;
      // square root of exponent
      E_O = (Regime & 1'b1) ? ((Exponent >> 1) + 2) : (Exponent >> 1);
      if ((Mantissa << 1) == '0) begin
        Sqrt_Mant = (Exponent & 1'b1) ? 64'hB504F333F9DE6800 : 64'h8000000000000000;
      end else begin
        // determine index to access lookup tables
        index = (Mantissa >> 28) & 4'h7;
        // piecewise reciprocal square root linear approximation y=mx+c
        slope = (Exponent & 1'b1) ? slopes_odd[index] : slopes_even[index];
        intercept = (Exponent & 1'b1) ? intercepts_odd[index] : intercepts_even[index];
        mx = -((slope * Mantissa) >> 31);
        x = (mx + intercept) << 1; // initial reciprocal square root
        // Newton-Raphson algorithm to approximate reciprocal of square root
        // Need to make it modular for multi-cycle, replace the for loop
        // too hardware-intensive
        for (int i=0; i<2; i++) begin
          sqr_x = (x * x) >> 1;
          sqr_x = (Exponent & 1'b1) ? (sqr_x << 1) : sqr_x;
          error = (96'hC00000000000000000000000 - (Mantissa * sqr_x)) >> 64;
          x = ((x >> 1) * error) >> 30;
        end
		  Sqrt_Mant = (Mantissa * (x>>1)) ;
		  Sqrt_Mant = (!(Exponent & 1'b1))? (Sqrt_Mant >> 1) : Sqrt_Mant;
		  Sqrt_Mant = Sqrt_Mant << 2;
      end
      // adjust for rounding
      sign_Exponent_O = Sqrt_regime[RS];
      R_O = (sign_Exponent_O) ? -Sqrt_regime : Sqrt_regime+1;
    end
  end
endmodule