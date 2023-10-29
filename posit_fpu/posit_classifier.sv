
module posit_classifier #(
  parameter posit_pkg::posit_format_e   pFormat = posit_pkg::posit_format_e'(0),
  parameter int unsigned             NumOperands = 1,
  localparam int unsigned WIDTH = posit_pkg::posit_width(pFormat)
) (
  input  var logic               [NumOperands-1:0][WIDTH-1:0] operands_i,
  output posit_pkg::posit_info_t [NumOperands-1:0]            info_o
);

  localparam int unsigned ES = posit_pkg::exp_bits(pFormat);
  posit_extractor #(WIDTH, ES) extractor ();

  typedef struct packed {
    logic signed sign;
    logic signed [$clog2(WIDTH):0] regime;
    logic [ES-1:0] exponent;
    logic [WIDTH-1:0] fraction;
    logic signed [WIDTH-2:0] remain;
    logic NaR;
    logic zero;
  } posit_result_t;

  // Iterate through all operands
  for (genvar op = 0; op < int'(NumOperands); op++) begin : gen_num_values
    posit_result_t posit;
    logic is_zero;
    logic is_NaR;
    logic is_pos;
    logic is_neg;
    
    // ---------------
    // Classify Input
    // ---------------
    always_comb begin : classify_input
      posit         = extractor.extract(operands_i[op]);
      is_zero       = posit.zero;
      is_NaR        = posit.NaR;
      is_pos 		  = (posit.sign == '0) && ~is_zero;
      is_neg		  = (posit.sign == '1) && ~is_NaR;
      // Assign output for current input
      info_o[op].is_zero = is_zero;
      info_o[op].is_NaR = is_NaR;
      info_o[op].is_pos = is_pos;
      info_o[op].is_neg = is_neg;
    end
  end
endmodule