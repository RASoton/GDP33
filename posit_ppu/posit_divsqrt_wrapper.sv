
module posit_divsqrt_wrapper #(
	parameter posit_pkg::posit_format_e   pFormat = posit_pkg::posit_format_e'(0),
	localparam int unsigned N = posit_pkg::posit_width(pFormat),
	localparam int unsigned ES = posit_pkg::exp_bits(pFormat),
	localparam int RS = $clog2(N)
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
	//Define the states
	typedef enum logic [2:0] {
		IDLE, EXTRACT, DIV, SQRT, RND, DONE
	} state_t;
	
	state_t state, next_state;
	
    //Operands 
	logic signed Sign1, Sign2;
	logic signed [RS:0] k1,k2;
	logic [ES-1:0] Exponent1, Exponent2;
	logic [N-1:0] Mantissa1, Mantissa2;
	logic signed [N-2:0] InRemain1, InRemain2;
	logic NaR1, NaR2, Zero1, Zero2;

	logic [2*N-1:0] Mant, Div_Mant_N, Sqrt_Mant_N;
	logic [RS+ES+4:0]Total_EO, Total_EO_div, Total_EO_sqrt, Total_EON;
	logic [ES-1:0] E_O, E_O_div, E_O_sqrt;
	logic signed [RS+4:0] R_O, R_O_div, R_O_sqrt, sumR;
	logic Inf, Zero, Sign;
	logic [N-1:0] Result;

	logic enable_div, enable_sqrt, enable_rnd, done_div, done_sqrt, done_rnd;

	//Extraction for operand_a
	posit_extraction #(pFormat) extractor1
	(
	 .In		(Operand_a_DI),
	 .Sign		(Sign1), 
	 .k			(k1), 
	 .Exponent	(Exponent1), 
	 .Mantissa	(Mantissa1), 
	 .InRemain	(InRemain1), 
	 .NaR		(NaR1), 
	 .zero		(Zero1)
	);

    //Extraction for operand_b
	posit_extraction #(pFormat) extractor2
	(
	 .In		(Operand_b_DI),
	 .Sign		(Sign2), 
	 .k			(k2), 
	 .Exponent	(Exponent2), 
	 .Mantissa	(Mantissa2), 
	 .InRemain	(InRemain2), 
	 .NaR		(NaR2), 
	 .zero		(Zero2)
	);

	//Division
	posit_div #(pFormat) div
    (
	 .Enable(enable_div),
	 .Done(done_div),
	 .Sign(Sign),
	 .Sign1(Sign1),
	 .Sign2(Sign2),
	 .k1(k1),
	 .k2(k2),
	 .Exponent1(Exponent1),
	 .Exponent2(Exponent2),
	 .Mantissa1(Mantissa1),
	 .Mantissa2(Mantissa2),
	 .InRemain1(InRemain1),
	 .InRemain2(InRemain2),
	 .NaR(NaR),
	 .NaR1(NaR1),
	 .NaR2(NaR2),
	 .zero(Zero),
	 .zero1(Zero1),
	 .zero2(Zero2),
	 .Div_Mant_N(Div_Mant_N),
	 .Total_EO(Total_EO_div),
	 .E_O(E_O_div),
	 .R_O(R_O_div),
	 .sumR(sumR)
	);

	//Square Root
    posit_sqrt #(pFormat) sqrt(
     .Enable(enable_sqrt),
	 .Done(done_sqrt),
     .Sign(Sign1), 
     .Regime(k1), 
     .Exponent(Exponent1), 
     .Mantissa(Mantissa1), 
	 .E_O(E_O_sqrt),
	 .R_O(R_O_sqrt),
	 .Total_EO(Total_EO_sqrt),
	 .Sqrt_Mant(Sqrt_Mant_N),
	 .NaR(NaR)
    );

	//RNE
	posit_rounding #(pFormat) rnd(
	 .Enable(enable_rnd),
	 .Done(done_rnd),
	 .Sign(sign),
	 .R_O(R_O),
	 .E_O(E_O),
	 .Mant(Mant),
	 .Total_EO(Total_EO),
	 .NaR(NaR),
	 .zero(zero),
	 .OUT(Result)
	);

	always_ff @(posedge Clk_CI or negedge Rst_RBI) begin
		if (!Rst_RBI) begin
			state <= IDLE;
			Result_DO <= 0;
			Fflags_SO <= 0;
			Done_SO <= 1'b0;
			Ready_SO <= 1'b0;
		end else begin
			state <= next_state;
			if(state == DONE) begin
				Result_DO <= Result;
				Done_SO <= 1'b1;
				Ready_SO <= 1'b1;
				Fflags_SO <= '0;
			end
		end
	end


	always_comb begin
		next_state = state;
		enable_div = 1'b0;
		enable_sqrt = 1'b0;
		enable_rnd = 1'b0;

		unique case (state)
			IDLE: begin
				E_O = '0;
				R_O = '0;
				Mant = '0;
				Total_EO = '0;
				if (Div_start_SI)
					next_state = EXTRACT;
				else if (Sqrt_start_SI)
					next_state = EXTRACT;
			end
			EXTRACT: begin
                next_state = Div_start_SI ? DIV : SQRT;
            end
            DIV: begin
                enable_div = 1'b1;
				E_O = E_O_div;
				R_O = R_O_div;
				Mant = Div_Mant_N;
				Total_EO = Total_EO_div;
				if(done_div)
					next_state = RND;
            end
            SQRT: begin
                enable_sqrt = 1'b1;
				E_O = E_O_sqrt;
				R_O = R_O_sqrt;
				Mant = Sqrt_Mant_N;
				Total_EO = Total_EO_sqrt;
				if(done_sqrt)
					next_state = RND;
            end
            RND: begin
				enable_rnd = 1'b1;
				if(done_rnd)
                	next_state = DONE;
            end
            DONE: begin
				enable_rnd = 1'b1;
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
	end

endmodule