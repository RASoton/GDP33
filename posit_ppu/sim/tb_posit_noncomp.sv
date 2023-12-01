
module tb_posit_noncomp;
  localparam posit_pkg::posit_format_e pFormat = posit_pkg::posit_format_e'(0);
	localparam int unsigned WIDTH = posit_pkg::posit_width(pFormat);

  logic                     clk_i;
  logic                     rst_ni;
  logic [1:0][WIDTH-1:0]    operands_i; 
  posit_pkg::roundmode_e    rnd_mode_i;
  posit_pkg::operation_e    op_i;
	logic 										op_mod_i;
	logic											tag_i;
  logic                     in_valid_i;
  logic                     in_ready_o;
  logic                     flush_i;
  logic [WIDTH-1:0]         result_o;
  posit_pkg::status_t       status_o;
  posit_pkg::classmask_e    class_mask_o;
  logic                     is_class_o;
  logic	                    tag_o;
  logic                     out_valid_o;
  logic                     out_ready_i;
  logic                     busy_o;
 	logic  signa, signb;

	posit_noncomp #(.pFormat(pFormat)) dut (.*);

	initial begin
		clk_i = 1'b0;
		forever #5 clk_i = ~clk_i;
	end

	initial begin
		rst_ni = 1'b0;
		#10;
		rst_ni = 1'b1;
		#10;

		// SGNJ
		op_i = posit_pkg::SGNJ;
    rnd_mode_i = posit_pkg::RNE;
		operands_i = {32'b01001101000111101011100001010010, 32'b11000000000000000000000000000000};

	
		#500;
		$stop;

	end		

	initial begin
		$monitor("IN1=%b, IN2=%b, Result=%b", operands_i[0], operands_i[1], result_o);
	end

endmodule