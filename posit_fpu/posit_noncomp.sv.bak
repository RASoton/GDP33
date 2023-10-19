module posit_noncomp #(
    localparam int unsigned WIDTH = 32
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
logic [31:0] compare_result;
logic signed [WIDTH-1:0] src1;
logic signed [WIDTH-1:0] src2;

logic [31:0] sign_result;

logic equal;
logic less;

assign src1 = operands_i[0];
assign src2 = operands_i[1];
assign invalid_input = (posit_pkg::NAR == operands_i[0]) || (posit_pkg::NAR == operands_i[1]);

always_comb
begin : Comp

  equal = (src1 == src2);
  less = (src1 < src2);

  case (rnd_mode_i)
    posit_pkg::RNE: begin compare_result = 32'(unsigned'(equal | less)); end
    posit_pkg::RTZ: begin compare_result = 32'(unsigned'(less)); end
    posit_pkg::RDN: begin compare_result = 32'(unsigned'(equal)); end
    default : compare_result = 32'b0;
  endcase
end

always_comb
begin : Output
  status_o = '0;
  status_o.NV = invalid_input;
  case (op_i)
    posit_pkg::SGN: begin result_o = sign_result; end
    posit_pkg::CMP: begin result_o = compare_result; end
    default: result_o = 32'b0;
  endcase
end

endmodule
