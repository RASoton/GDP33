
`timescale 1ns / 1ps

module tb_divsqrt_wrapper;
	
	localparam N = 32;

	logic Clk_CI;
	logic Rst_RBI;
  	logic Div_start_SI;
	logic Sqrt_start_SI;
	logic [N-1:0] Operand_a_DI;
	logic [N-1:0] Operand_b_DI;
	posit_pkg::roundmode_e RM_SI;
	logic [1:0] Format_sel_SI;
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
		Rst_RBI = 1;
		Div_start_SI = 0;
        Sqrt_start_SI = 0;
        Operand_a_DI = 0;
        Operand_b_DI = 0;
		
		#5 Rst_RBI = 0;
		#20 Rst_RBI = 1;
		
		#10;
		Operand_a_DI = 32'b01101011001100011100011100101010;
		Operand_b_DI = 32'b01001000000000000000000000000000;
		Div_start_SI = 1;
    	#100;
		Operand_a_DI = 32'b01101011001100011100011100101010;
		Operand_b_DI = 32'b01001000000000000000000000000000;
		Div_start_SI = 0;
        Sqrt_start_SI = 1;
    	#10;

		#100 $stop;
    	
  	end

	always @(Result_DO) begin
		$display("IN1=%b, IN2=%b, DIV=%b, SQRT=%b, Result=%b", Operand_a_DI, Operand_b_DI, Div_start_SI, Sqrt_start_SI, Result_DO);
	end

endmodule