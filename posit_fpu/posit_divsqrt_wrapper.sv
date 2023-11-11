
module posit_divsqrt_wrapper #(
	parameter N = 32,
	parameter ES = 2,
	parameter RS = $clog2(N)
) (
	input logic Clk_CI,
	input logic Rst_RBI,
 	input logic Div_start_SI,
	input logic Sqrt_start_SI,
	input logic [N-1:0] Operand_a_DI,
	input logic [N-1:0] Operand_b_DI,
	input posit_pkg::roundmode_e RM_SI,
	input logic [1:0] Format_sel_SI,
	input logic Kill_SI,
	output logic [N-1:0] Result_DO,
	output posit_pkg::status_t Fflags_SO,
	output logic Ready_SO,
	output logic Done_SO
);
    //Operands for extraction
	logic signed Sign1, Sign2;
	logic signed [RS:0] k1,k2;
	logic [ES-1:0] Exponent1, Exponent2;
	logic [N-1:0] Mantissa1, Mantissa2;
	logic signed [N-2:0] InRemain1, InRemain2;
	logic NaR1, NaR2,zero1,zero2;

	//Operands for division
	logic [2*N-1:0] Div_Mant_N;
	logic [RS+ES+4:0]Total_EO, Total_EON;
	logic [ES-1:0] E_O;
	logic signed [RS+4:0] R_O,sumR;
	logic inf, zero, Sign;

	//Operands for square root
	logic [N-1:0] sqrt_result;

	posit_extraction #(.N(N), .ES(ES)) Extract_IN1 
	(
	 .In		(Operand_a_DI),
	 .Sign		(Sign1), 
	 .k			(k1), 
	 .Exponent	(Exponent1), 
	 .Mantissa	(Mantissa1), 
	 .InRemain	(InRemain1), 
	 .inf		(NaR1), 
	 .zero		(zero1)
	);

	posit_extraction #(.N(N), .ES(ES)) Extract_IN2 
	(
	 .In		(Operand_b_DI),
	 .Sign		(Sign2), 
	 .k			(k2), 
	 .Exponent	(Exponent2), 
	 .Mantissa	(Mantissa2), 
	 .InRemain	(InRemain2), 
	 .inf		(NaR2), 
	 .zero		(zero2)
	);


	posit_div #(.N(N), .ES(ES)) Divide(.*);

  
	posit_sqrt #(.N(N), .ES(ES)) sqrt(.sign(Sign1), .regime(k1), .exponent(Exponent1), .fraction(Mantissa1), .zero(zero1), .result(sqrt_result));


	
endmodule