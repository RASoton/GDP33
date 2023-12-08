
`timescale 1ns / 1ps

module tb_divsqrt_wrapper;
	
	localparam N = 32;

	logic Clk_CI;
	logic Rst_RBI;
  logic Div_start_SI;
	logic Sqrt_start_SI;
	logic [N-1:0] Operand_a_DI;
	logic [N-1:0] Operand_b_DI;
	logic Kill_SI;
	logic [N-1:0] Result_DO;
	posit_pkg::status_t Fflags_SO;
	logic Ready_SO;
	logic Done_SO;

  posit_divsqrt_wrapper dut (.*);

	initial begin
		Clk_CI = 0;
  		forever #5 Clk_CI = ~Clk_CI; 
	end


  	initial begin
		Rst_RBI = 0;
		Kill_SI = 1'b0;
		Div_start_SI = 0;
    Sqrt_start_SI = 0;
		
		#10 Rst_RBI = 1;
		
		#10;
		Div_start_SI = 1;
		Operand_a_DI = 32'b01101011001100011100011100101010;
		Operand_b_DI = 32'b01001000000000000000000000000000;


		#10;
		Sqrt_start_SI = 1;
		Div_start_SI = 0;
		Operand_a_DI = 32'b01001011111100000000011100101010;
		Operand_b_DI = 32'b01101000000000000000000000000000;


		#100 $stop;
    	
  	end

	always @(Result_DO) begin
		$display("IN1=%b, IN2=%b, DIV=%b, SQRT=%b, Result=%b, Status=%b", Operand_a_DI, Operand_b_DI, Div_start_SI, Sqrt_start_SI, Result_DO, Fflags_SO);
	end

endmodule