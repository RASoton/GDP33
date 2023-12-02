
module tb_opgroup_fmt_slice;
  localparam posit_pkg::posit_format_e  pFormat = posit_pkg::posit_format_e'(0);
  localparam posit_pkg::opgroup_e        OpGroup       = posit_pkg::DIVSQRT;
  localparam int unsigned WIDTH = posit_pkg::posit_width(pFormat);
  localparam int unsigned ExtRegEnaWidth = 1;
  localparam type TagType = logic;
  logic clk_i, rst_ni;
  logic [1:0][WIDTH-1:0]       operands_i; // 2 operands
  logic [1:0]                  is_boxed_i; // 2 operands
  posit_pkg::roundmode_e       rnd_mode_i;
  posit_pkg::operation_e       op_i;
  logic                        op_mod_i;
  TagType                      tag_i;
  logic                        in_valid_i;
  logic                        in_ready_o;
  logic                        flush_i;
  logic [WIDTH-1:0]            result_o;
  posit_pkg::status_t          status_o;
  logic                        extension_bit_o;
  TagType                      tag_o;
  logic                        out_valid_o;
  logic                        out_ready_i;
  logic                        busy_o;
  logic [ExtRegEnaWidth-1:0]   reg_ena_i;

  posit_opgroup_fmt_slice #(.OpGroup(OpGroup)) dut  (.*);
	
  initial begin
    clk_i = 0;
    forever #5 clk_i = ~clk_i; 
  end

  initial begin
  rst_ni = 1'b1;
	flush_i = 1'b0;
  op_i = posit_pkg::DIV;
	//operands_i = {32'b0, 32'b0};  

	#5 rst_ni = 1'b0;
	#20 rst_ni = 1'b1;

  operands_i = {32'b01001011001100011100011100101010, 32'b01001000111000000000000000000000};    
 	op_i = posit_pkg::DIV;           
	in_valid_i = 1'b1;
	out_ready_i = 1'b0;


	#1000; 
	$stop;
  end

endmodule