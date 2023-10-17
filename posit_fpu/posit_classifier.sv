
module posit_classifier #(
  parameter posit_pkg::posit_format_e   pFormat = posit_pkg::posit_format_e'(0),
  parameter int unsigned             NumOperands = 1,
  // Do not change
  localparam int unsigned WIDTH = posit_pkg::posit_width(pFormat)
) (
  input  logic                [NumOperands-1:0][WIDTH-1:0] operands_i,
  input  logic                [NumOperands-1:0]            is_boxed_i,
  output posit_pkg::posit_info_t [NumOperands-1:0]            info_o
);

  localparam int unsigned REGIME_BITS = posit_pkg::regime_bits(pFormat);
  localparam int unsigned EXP_BITS = posit_pkg::exp_bits(pFormat);
  localparam int unsigned FRAC_BITS = posit_pkg::frac_bits(pFormat);


  // Type definition
  typedef struct packed {
   logic sign;
   logic [REGIME_BITS-1:0] regime;
   logic [EXP_BITS-1:0] exponent;
   logic [FRAC_BITS-1:0] fraction;
	} posit_t;

  // Iterate through all operands
  for (genvar op = 0; op < int'(NumOperands); op++) begin : gen_num_values

    posit_t value;
    logic is_zero;
    logic is_inf;
    logic is_NaR;
    logic is_pos;
    logic is_neg;

    // ---------------
    // Classify Input
    // ---------------
    always_comb begin : classify_input
      value         = operands_i[op];
      is_boxed      = is_boxed_i[op];
      is_zero       = is_boxed && (value.sign == '0) && (value.regime == '0) && (value.exponent == '0) && (value.fraction == '0);
      is_inf 		  = is_boxed && (value.sign == '1) && (value.regime == '0) && (value.exponent == '0) && (value.fraction == '0);
      is_NaR 		  = is_boxed && (value == {WIDTH{1'b1}});
      is_pos 		  = is_boxed && (value.sign == '0) && ~is_zero && ~is_NaR;
      is_neg		  = is_boxed && (value.sign == '1) && ~is_zero && ~is_NaR;
      // Assign output for current input
      info_o[op].is_zero = is_zero;
      info_o[op].is_inf = is_inf;
      info_o[op].is_NaR = is_NaR;
      info_o[op].is_pos = is_pos;
      info_o[op].is_neg = is_neg;
    end
  end
endmodule