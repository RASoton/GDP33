
`timescale 1ns/1ps

module tb_posit_top;
  parameter posit_pkg::posit_features_t       Features       = posit_pkg::POSIT32_CONFIG;
  parameter posit_pkg::posit_implementation_t Implementation = posit_pkg::DEFAULT_NOREGS;
  localparam int unsigned WIDTH        = Features.Width;
  localparam int unsigned NUM_OPERANDS = 3;
  logic clk_i;
  logic rst_ni;
  logic [NUM_OPERANDS-1:0][WIDTH-1:0] operands_i;
  posit_pkg::roundmode_e              rnd_mode_i; // Unused
  posit_pkg::operation_e              op_i;
  logic                               op_mod_i; // Unused
  posit_pkg::posit_format_e           src_fmt_i;
  posit_pkg::posit_format_e           dst_fmt_i;
  posit_pkg::int_format_e             int_fmt_i;
  logic                               vectorial_op_i; // Unused
  logic                               tag_i;
  logic                               simd_mask_i; // Unused
  logic                               in_valid_i;
  logic                               in_ready_o;
  logic                               flush_i;
  logic [WIDTH-1:0]                   result_o;
  posit_pkg::status_t                 status_o;
  logic                               tag_o;
  logic                               out_valid_o;
  logic                               out_ready_i;
  logic                               busy_o;

  posit_top dut (.*);

  initial begin
    clk_i = 0;
    forever #5 clk_i = ~clk_i; 
  end

  initial begin
    rst_ni = 1'b0;
		//operands_i = {32'h0, 32'h0};
		op_i = posit_pkg::DIV;
		src_fmt_i = posit_pkg::POSIT32;
		dst_fmt_i = posit_pkg::POSIT32;
		int_fmt_i = posit_pkg::INT32;
		flush_i = 1'b0;

		#10 rst_ni = 1'b1;
		in_valid_i = 1'b1;
    operands_i = {32'b01001011001100011100011100101010, 32'b01001000111000000000000000000000, 32'b01101000111000000000000000000000};    
   	op_i = posit_pkg::DIV;           
		out_ready_i = 1'b1;

		#10;
    operands_i = {32'b01001011001100011100011100101010, 32'b01101000111000000000000000000000, 32'b01110000111000000000000000000000};    
		#10;
    operands_i = {32'b01001011001100011100011100101010, 32'b01000000111000000000000000000000, 32'b01001000111000000000000000000000};   
		#10;
    operands_i = {32'b01001011001100011100011100101010, 32'b01001000000000000000000000000000, 32'b01001000000000000000000000000000};   

    #200;

    $stop; 
  end

endmodule