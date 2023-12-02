
module tb_posit_fma;
  localparam posit_pkg::posit_format_e   pFormat  = posit_pkg::posit_format_e'(0);
	localparam int unsigned                WIDTH    = posit_pkg::posit_width(pFormat);
	localparam int unsigned                ES       = posit_pkg::exp_bits(pFormat);
	localparam int unsigned                RS       = $clog2(WIDTH);

  logic                     clk_i;
  logic                     rst_ni;
  logic [2:0][WIDTH-1:0]    operands_i; // 3 operands
  posit_pkg::operation_e    op_i;
  logic                     op_mod_i;
  logic                     tag_i;
  logic                     in_valid_i;
  logic                     in_ready_o;
  logic                     flush_i;
  logic [WIDTH-1:0]         result_o;
  posit_pkg::status_t       status_o;
  logic                     tag_o;
  logic                     out_valid_o;
  logic                     out_ready_i;
  logic                     busy_o;

	posit_fma #(.pFormat(pFormat)) dut (.*);

	initial begin
		clk_i = 0;
		forever #5 clk_i = ~clk_i;
	end

	initial begin
		op_mod_i = 0;
		in_valid_i = 1;
		out_ready_i = 1;
		flush_i = 0;

		rst_ni = 0;
		#10 rst_ni = 1;
		
		op_i = posit_pkg::FMADD;
		operands_i = {32'b01001100100100001110010101100000, 32'b01001000000000000000000000000000, 32'b01010011010101110000101000111101};

		#10;
		$stop;
	end

	initial begin
		$monitor("Result= %b", result_o);
	end

endmodule