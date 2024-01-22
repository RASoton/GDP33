// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

// Language: SystemVerilog
// Description: posit-based classification

module posit_classifier #(
  parameter posit_pkg::posit_format_e   pFormat = posit_pkg::posit_format_e'(0),
  parameter int unsigned             NumOperands = 1,
  localparam int unsigned N = posit_pkg::posit_width(pFormat),
  localparam int unsigned ES = posit_pkg::exp_bits(pFormat)
) (
  input  var logic               [NumOperands-1:0][N-1:0] operands_i,
  output posit_pkg::posit_info_t [NumOperands-1:0]            info_o
);

  for (genvar op = 0; op < int'(NumOperands); op++) begin : gen_num_values
  
	logic signed [N-1:0] In;
	logic signed Sign;
	logic signed [$clog2(N):0] k;
	logic [ES-1:0] Exponent;
	logic [N-1:0] Mantissa;
	logic signed [N-2:0] InRemain;
	logic NaR;
	logic zero;

  	posit_extraction #(pFormat) extractor 
	(
	 .In(operands_i[op]),
	 .Sign(Sign),
	 .k(k),
	 .Exponent(Exponent),
	 .Mantissa(Mantissa),
	 .InRemain(InRemain),
	 .NaR(NaR),
	 .zero(zero)
	);

    always_comb begin : classify_input
      info_o[op].is_zero = zero;
      info_o[op].is_NaR = NaR;
      info_o[op].is_pos = (Sign == '0) && ~zero;
      info_o[op].is_neg = (Sign == '1) && ~NaR;
    end
  end
endmodule