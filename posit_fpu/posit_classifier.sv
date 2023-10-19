
module posit_classifier #(
  parameter posit_pkg::posit_format_e   pFormat = posit_pkg::posit_format_e'(0),
  parameter int unsigned             NumOperands = 1,
  localparam int unsigned WIDTH = posit_pkg::posit_width(pFormat)
) (
  input  var logic               [NumOperands-1:0][WIDTH-1:0] operands_i,
  output posit_pkg::posit_info_t [NumOperands-1:0]            info_o
);

  localparam int unsigned EXP_BITS = posit_pkg::exp_bits(pFormat);
  localparam int unsigned MAX_REGIME_BITS = posit_pkg::max_regime_bits(pFormat);

  // Iterate through all operands
  for (genvar op = 0; op < int'(NumOperands); op++) begin : gen_num_values
    logic sign;
    logic signed [MAX_REGIME_BITS:0] regime;
    logic [EXP_BITS-1:0] exponent;
    logic [WIDTH-1:0] fraction; 
    logic signed [WIDTH-2:0] remain;
    logic is_zero;
    logic is_inf;
    logic is_NaR;
    logic is_pos;
    logic is_neg;
	 posit_extraction #(.N(WIDTH), .ES(EXP_BITS)) Extract_IN1 (.In(operands_i[op]), .Sign(sign), .k(regime), .Exponent(exponent), .Mantissa(fraction), .InRemain(remain), .inf(is_inf), .zero(is_zero));
    // ---------------
    // Classify Input
    // ---------------
    always_comb begin : classify_input
      is_NaR        = (operands_i[op] == {WIDTH{1'b1}});
      is_pos 		  = (sign == '0) && ~is_zero;
      is_neg		  = (sign == '1) && ~is_NaR && ~is_inf;
      // Assign output for current input
      info_o[op].is_zero = is_zero;
      info_o[op].is_inf = is_inf;
      info_o[op].is_NaR = is_NaR;
      info_o[op].is_pos = is_pos;
      info_o[op].is_neg = is_neg;
    end
  end
endmodule