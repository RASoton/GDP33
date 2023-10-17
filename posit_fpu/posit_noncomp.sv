module posit_noncomp #(
    localparam unsigned int WIDTH = 32
) (
  input logic                  clk_i,
  input logic                  rst_ni,
  // Input signals
  input logic [1:0][WIDTH-1:0]     operands_i, // 2 operands
  input posit_pkg::operation_e     op_i,
  input posit_pkg::roundmode_e     rnd_mode_i,
  // Input Handshake
  input  logic                     in_valid_i,
  output logic                     in_ready_o,
  input  logic                     flush_i,
  // Output signals
  output logic [WIDTH-1:0]         result_o,
  output posit_pkg::status_t       status_o,
  // Output handshake
  output logic                     out_valid_o,
  input  logic                     out_ready_i,
  // Indication of valid data in flight
  output logic                     busy_o
);

  logic invalid_input;
  logic equal;
  logic less;
  signed logic [WIDTH-1:0] src1;
  signed logic [WIDTH-1:0] src2;

always_comb
begin : Comp

  src1 = operands_i[0];
  src2 = operands_i[1];

  invalid_input = (posit_pkg::POSIT_NAR == operands_i[0]) || (posit_pkg::POSIT_NAR == operands_i[1]);

  equal = (src1 == src2);
  less = (src1 < src2);

  if (!invalid_input)
    case (rnd_mode_i)
      posit_pkg::begin RNE:result_o = 32'(unsigned(equal | less)); end
      posit_pkg::begin RTZ:result_o = 32'(unsigned(less)); end
      posit_pkg::begin RDN:result_o = 32'(unsigned(equal)); end
      default : result_o = 0;
    endcase
  status_o = '0;
  status_o.NV = invalid_input;
end
endmodule