
`timescale 1ns / 1ps

module tb_posit_divsqrt;

	localparam int unsigned WIDTH = 32; 
	localparam int unsigned NUM_FORMATS = 1;
  localparam int unsigned ExtRegEnaWidth = 1;

	logic clk_i, rst_ni;
  var logic [1:0][WIDTH-1:0]       operands_i;
	var logic [NUM_FORMATS-1:0][1:0] is_boxed_i = '0; 
  posit_pkg::roundmode_e       rnd_mode_i = posit_pkg::RNE;
 	posit_pkg::operation_e       op_i; 
 	posit_pkg::posit_format_e    dst_fmt_i = posit_pkg::POSIT32;
 	logic                        tag_i = 1'b0;
  logic                        mask_i = 1'b0;
  logic                        aux_i = 1'b0;
  logic                        vectorial_op_i = 1'b0;
  logic                        in_valid_i;
  logic                        in_ready_o;
  logic                        divsqrt_done_o;
  logic                        simd_synch_done_i = 1'b1;
  logic                        divsqrt_ready_o;
  logic                        simd_synch_rdy_i = 1'b1;
  logic                        flush_i = 1'b0;
 	logic [WIDTH-1:0]            result_o;
 	posit_pkg::status_t          status_o;
  logic                        extension_bit_o;
  logic                        tag_o;
  logic                        mask_o;
  logic                        aux_o;
  logic                        out_valid_o;
  logic                        out_ready_i;
  logic                        busy_o;
  logic [ExtRegEnaWidth-1:0]   reg_ena_i = 1'b0;


  posit_divsqrt dut (.*);

	initial begin
		clk_i = 0;
  		forever #5 clk_i = ~clk_i; 
	end
  	initial begin
		rst_ni = 1'b0;
		op_i = posit_pkg::DIV;
		in_valid_i = 1'b1;
		operands_i = {32'b0, 32'b0};  

		#10 rst_ni = 1'b1;

   	operands_i = {32'b01001011001100011100011100101010, 32'b01001000111000000000000000000000};    
   	op_i = posit_pkg::SQRT;           
		out_ready_i = 1'b1;

		#10;
		operands_i = {32'b01001011001100010000011100101010, 32'b01001000111000000000011100000000}; 
   	op_i = posit_pkg::DIV;  

		#10;
		operands_i = {32'b01101011001100010000011100101010, 32'b01001000111000000011000000000000};  
   	op_i = posit_pkg::SQRT;  

		#10;
		operands_i = {32'b01001011001100011100000000101010, 32'b01101000111000001100000000000000};  
   	op_i = posit_pkg::DIV;  

		#10;
		operands_i = {32'b01001011001100011100000100101000, 32'b01111010001111100000000000000000};  
   	op_i = posit_pkg::SQRT;  

		#200; 
		$stop;
    	
  	end

endmodule