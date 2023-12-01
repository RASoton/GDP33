
`include "registers.svh"

module posit_divsqrt #(
  parameter posit_pkg::posit_format_e  pFormat = posit_pkg::posit_format_e'(0),
  // Do not change
  localparam int unsigned WIDTH = posit_pkg::posit_width(pFormat),
	localparam int unsigned ES    = posit_pkg::exp_bits(pFormat),
	localparam int          RS    = $clog2(WIDTH)
) (
  input  logic                        clk_i,
  input  logic                        rst_ni,
  // Input signals
  input  logic [1:0][WIDTH-1:0]       operands_i, // 2 operands
  input  posit_pkg::roundmode_e       rnd_mode_i,
  input  posit_pkg::operation_e       op_i,
  input  logic                        tag_i,
  // Input Handshake
  input  logic                        in_valid_i,
  output logic                        in_ready_o,
  input  logic                        flush_i,
  // Output signals
  output logic [WIDTH-1:0]            result_o,
  output posit_pkg::status_t          status_o,
  output logic                        tag_o,
  // Output handshake
  output logic                        out_valid_o,
  input  logic                        out_ready_i,
  // Indication of valid data in flight
  output logic                        busy_o
);

  assign in_ready_o = out_ready_i ;
  logic div_valid, sqrt_valid; 
  assign div_valid   = in_valid_i & (op_i == posit_pkg::DIV) & in_ready_o & ~flush_i;
  assign sqrt_valid  = in_valid_i & (op_i != posit_pkg::DIV) & in_ready_o & ~flush_i;

	logic signed Sign1, Sign2;
	logic signed [RS:0] k1,k2;
	logic [ES-1:0] Exponent1, Exponent2;
	logic [WIDTH-1:0] Mantissa1, Mantissa2;
	logic signed [WIDTH-2:0] InRemain1, InRemain2;
	logic NaR1, NaR2, zero1, zero2;

	logic [2*WIDTH-1:0] Mant, Div_Mant_N, Sqrt_Mant_N;
	logic [RS+ES+4:0]Total_EO, Total_EO_div, Total_EO_sqrt, Total_EON;
	logic [ES-1:0] E_O, E_O_div, E_O_sqrt;
	logic signed [RS+4:0] R_O, R_O_div, R_O_sqrt, sumR;
	logic zero, zero_div;
  logic NaR, NaR_div, NaR_sqrt;
	logic Sign, Sign_div, Sign_sqrt;
	logic [WIDTH-1:0] Result;
	logic NV, DZ, OF, UF, NX, Done;
	posit_pkg::status_t status;
	logic Div_enable, Sqrt_enable;

	//Extraction for operand_a
	posit_extraction #(pFormat) extractor1
	(
	 .In		    (operands_i[0]),
	 .Sign		  (Sign1), 
	 .k			    (k1), 
	 .Exponent	(Exponent1), 
	 .Mantissa	(Mantissa1), 
	 .InRemain	(InRemain1), 
	 .NaR		    (NaR1), 
	 .zero		  (zero1)
	);

    //Extraction for operand_b
	posit_extraction #(pFormat) extractor2
	(
	 .In		    (operands_i[1]),
	 .Sign		  (Sign2), 
	 .k			    (k2), 
	 .Exponent	(Exponent2), 
	 .Mantissa	(Mantissa2), 
	 .InRemain	(InRemain2), 
	 .NaR		    (NaR2), 
	 .zero		  (zero2)
	);

	//Division
	posit_div #(pFormat) div
    (
	 .Enable     (Div_enable),
	 .Sign1      (Sign1),
	 .Sign2      (Sign2),
	 .k1         (k1),
	 .k2         (k2),
	 .Exponent1  (Exponent1),
	 .Exponent2  (Exponent2),
	 .Mantissa1  (Mantissa1),
	 .Mantissa2  (Mantissa2),
	 .InRemain1  (InRemain1),
	 .InRemain2  (InRemain2),
	 .NaR1       (NaR1),
	 .NaR2       (NaR2),
	 .zero1      (zero1),
	 .zero2      (zero2),
	 .Sign       (Sign_div),
	 .Div_Mant_N (Div_Mant_N),
	 .Total_EO   (Total_EO_div),
	 .E_O        (E_O_div),
	 .R_O        (R_O_div),
	 .sumR       (sumR),
	 .NaR        (NaR_div),
	 .zero       (zero_div),
	 .OF         (OF),
	 .UF         (UF)
	);

	//Square Root
  posit_sqrt #(pFormat) sqrt(
   .Enable    (Sqrt_enable),
   .Sign      (Sign1), 
   .Regime    (k1), 
   .Exponent  (Exponent1), 
   .Mantissa  (Mantissa1), 
	 .E_O       (E_O_sqrt),
	 .R_O       (R_O_sqrt),
	 .Total_EO  (Total_EO_sqrt),
	 .Sqrt_Mant (Sqrt_Mant_N),
	 .NaR       (NaR_sqrt)
  );

	//RNE
	posit_rounding #(pFormat) rnd(
	 .Sign     (Sign),
	 .R_O      (R_O),
	 .E_O      (E_O),
	 .Mant     (Mant),
	 .Total_EO (Total_EO),
	 .NaR      (NaR),
	 .zero     (zero),
	 .OUT      (Result),
	 .NX       (NX)
	);

	always_comb begin
	  Div_enable = 1'b0;
	  Sqrt_enable = 1'b0;
		NV=0; DZ=0;
		if (div_valid) begin
			Div_enable = 1'b1;
			Sign = Sign_div;
			E_O = E_O_div;
			R_O = R_O_div;
			Mant = Div_Mant_N;
			Total_EO = Total_EO_div;
			zero = zero_div;
			NaR = NaR_div;
			NV = NaR;
			DZ = (zero2)? 1:0;
		end else if (sqrt_valid) begin
			Sqrt_enable = 1'b1;
			Sign = Sign1;
			E_O = E_O_sqrt;
			R_O = R_O_sqrt;
			Mant = Sqrt_Mant_N;
			Total_EO = Total_EO_sqrt;
			zero = zero1;
			NaR = NaR_sqrt;
			NV = NaR;
			DZ = 1'b0;
		end
	end


  // --------------
  // Output Select
  // --------------
  assign result_o        = Result;
  assign status_o        = {NV, DZ, OF, UF, NX};
  assign extension_bit_o = 1'b1; // always NaN-Box result
  assign tag_o           = tag_i;
  assign out_valid_o     = in_valid_i;
  assign busy_o          = in_valid_i;

endmodule