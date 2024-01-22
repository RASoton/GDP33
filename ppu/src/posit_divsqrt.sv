// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.


// Language: SystemVerilog
// Description: posit-based division and square root 

module posit_divsqrt #(
  parameter posit_pkg::posit_format_e  pFormat = posit_pkg::posit_format_e'(0),
  localparam int unsigned WIDTH = posit_pkg::posit_width(pFormat),
  localparam int unsigned ES    = posit_pkg::exp_bits(pFormat),
  localparam int          RS    = $clog2(WIDTH)
) (
  input  logic                        clk_i,
  input  logic                        rst_ni,
  // Input signals
  input  logic [1:0][WIDTH-1:0]       operands_i, // 2 operands
  input  posit_pkg::roundmode_e       rnd_mode_i,
  input  posit_pkg::operation_e       op_i,
  input  logic                        tag_i,
  // Input Handshake
  input  logic                        in_valid_i,
  output logic                        in_ready_o,
  input  logic                        flush_i,
  // Output signals
  output logic [WIDTH-1:0]            result_o,
  output posit_pkg::status_t          status_o,
  output logic                        tag_o,
  // Output handshake
  output logic                        out_valid_o,
  input  logic                        out_ready_i,
  // Indication of valid data in flight
  output logic                        busy_o
);

  assign in_ready_o = out_ready_i ;

  // Operation type
  logic div_valid, sqrt_valid;
  assign div_valid   = in_valid_i & (op_i == posit_pkg::DIV) & ~flush_i;
  assign sqrt_valid  = in_valid_i & (op_i != posit_pkg::DIV) & ~flush_i;
  
  // Extract operands
  logic signed Sign1, Sign2;
  logic signed [RS:0] k1,k2;
  logic [ES-1:0] Exponent1, Exponent2;
  logic [WIDTH-1:0] Mantissa1, Mantissa2;
  logic signed [WIDTH-2:0] InRemain1, InRemain2;
  logic NaR1, NaR2, zero1, zero2;

  // Extraction for operand_a
  posit_extraction #(pFormat) extractor1
  (
   .In              (operands_i[0]),
   .Sign            (Sign1), 
   .k               (k1), 
   .Exponent        (Exponent1), 
   .Mantissa        (Mantissa1), 
   .InRemain        (InRemain1), 
   .NaR             (NaR1), 
   .zero            (zero1)
  );

  // Extraction for operand_b
  posit_extraction #(pFormat) extractor2
  (
   .In              (operands_i[1]),
   .Sign            (Sign2), 
   .k               (k2), 
   .Exponent        (Exponent2), 
   .Mantissa        (Mantissa2), 
   .InRemain        (InRemain2), 
   .NaR             (NaR2), 
   .zero            (zero2)
  );

  // Outputs from division and square root
  logic [2*WIDTH-1:0] Div_Mant_N, Sqrt_Mant_N;
  logic [ES-1:0] E_O_div, E_O_sqrt;
  logic signed [RS+4:0] R_O_div, R_O_sqrt;
  logic Sign_div, NaR_div, zero_div, SE_div;
  logic SE_sqrt;

  // Division
  posit_div #(pFormat) div
  (
   .Enable           (div_valid),
   .Sign1            (Sign1),
   .Sign2            (Sign2),
   .k1               (k1),
   .k2               (k2),
   .Exponent1        (Exponent1),
   .Exponent2        (Exponent2),
   .Mantissa1        (Mantissa1),
   .Mantissa2        (Mantissa2),
   .InRemain1        (InRemain1),
   .InRemain2        (InRemain2),
   .NaR1             (NaR1),
   .NaR2             (NaR2),
   .zero1            (zero1),
   .zero2            (zero2),
   .Sign             (Sign_div),
   .Div_Mant_N       (Div_Mant_N),
   .sign_Exponent_O  (SE_div),
   .E_O              (E_O_div),
   .R_O              (R_O_div),
   .NaR              (NaR_div),
   .zero             (zero_div)
  );

  // Square Root
  posit_sqrt_NR #(pFormat) sqrt
  (
   .Enable           (sqrt_valid),
   .Sign             (Sign1), 
   .Regime           (k1), 
   .Exponent         (Exponent1), 
   .Mantissa         (Mantissa1), 
   .E_O              (E_O_sqrt),
   .R_O              (R_O_sqrt),
   .Sqrt_Mant        (Sqrt_Mant_N),
   .sign_Exponent_O  (SE_sqrt)
  );

  // Rounding logic
  logic [WIDTH-1:0] Result;
  logic [ES-1:0] E_O;
  logic [2*WIDTH-1:0] Mant;
  logic signed [RS+4:0] R_O;
  logic Sign, NaR, zero, sign_Exponent, DZ;
  logic sign_Exponent_O;

  assign DZ = div_valid ? (zero2 ? 1'b1 : 1'b0) : 1'b0;
  assign E_O = div_valid ? E_O_div : E_O_sqrt;
  assign Mant = div_valid ? Div_Mant_N : Sqrt_Mant_N;
  assign R_O = div_valid ? R_O_div : R_O_sqrt;
  assign Sign = div_valid ? Sign_div : Sign1;
  assign NaR = div_valid ? (NaR_div || DZ) : Sign1;
  assign zero = div_valid ? zero_div : zero1;
  assign sign_Exponent_O = div_valid ? SE_div : SE_sqrt;

  posit_rounding #(pFormat) rnd
  (
   .Sign(Sign),
   .R_O(R_O),
   .E_O(E_O),
   .Comp_Mant_N(Mant),
   .sign_Exponent_O(sign_Exponent_O),
   .NaR(NaR),
   .zero(zero),
   .OUT(Result)
  );

  // Output logic
  assign result_o        = Result;
  assign status_o        = {1'b0, DZ, 1'b0, 1'b0, 1'b0};
  assign tag_o           = tag_i;
  assign out_valid_o     = in_valid_i;
  assign busy_o          = in_valid_i;

endmodule