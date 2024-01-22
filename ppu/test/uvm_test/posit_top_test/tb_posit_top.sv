
`timescale 1ns/1ps

module tb_posit_top;
  // constants
  localparam int unsigned WIDTH        = 32;
  localparam int unsigned ES           = 2;
  localparam int unsigned RS           = $clog2(WIDTH);
  localparam int unsigned NUM_OPERANDS = 3;

  // inputs and outputs
  logic clk_i;
  logic rst_ni;
  logic [NUM_OPERANDS-1:0][WIDTH-1:0] operands_i;
  posit_pkg::roundmode_e              rnd_mode_i; 
  posit_pkg::operation_e              op_i;
  logic                               op_mod_i; 
  posit_pkg::posit_format_e           src_fmt_i;
  posit_pkg::posit_format_e           dst_fmt_i;
  posit_pkg::int_format_e             int_fmt_i;
  logic                               vectorial_op_i; // Unused
  logic                               tag_i;
  logic                               simd_mask_i;    // Unused
  logic                               in_valid_i;
  logic                               in_ready_o;
  logic                               flush_i;
  logic [WIDTH-1:0]                   result_o;
  posit_pkg::status_t                 status_o;
  logic                               tag_o;
  logic                               out_valid_o;
  logic                               out_ready_i;
  logic                               busy_o;

  // Internal signals for checking
  logic signed S0, S1, S2, SR;
  logic signed [RS:0] K0, K1, K2, KR;
  logic [ES-1:0] E0, E1, E2, ER;
  logic [WIDTH-1:0] M0, M1, M2, MR;
  logic signed [WIDTH-2:0] IR0, IR1, IR2, IRR;
  logic NaR0, NaR1, NaR2, NaRR;
  logic zero0, zero1, zero2, zeroR;

  // Design under test
  posit_top dut (.*);

  // For checking purpose
  posit_extraction IN0    (.In(operands_i[0]),.Sign(S0),.k(K0),.Exponent(E0),.Mantissa(M0),.InRemain(IR0),.NaR(NaR0),.zero(zero0));
  posit_extraction IN1    (.In(operands_i[1]),.Sign(S1),.k(K1),.Exponent(E1),.Mantissa(M1),.InRemain(IR1),.NaR(NaR1),.zero(zero1));
  posit_extraction IN2    (.In(operands_i[2]),.Sign(S2),.k(K2),.Exponent(E2),.Mantissa(M2),.InRemain(IR2),.NaR(NaR2),.zero(zero2));
  posit_extraction result (.In(result_o     ),.Sign(SR),.k(KR),.Exponent(ER),.Mantissa(MR),.InRemain(IRR),.NaR(NaRR),.zero(zeroR));

  initial begin
    clk_i = 0;
    forever #5 clk_i = ~clk_i;  // 100 MHZ
  end

  initial begin
    // Settings
    src_fmt_i   = posit_pkg::POSIT32;
    dst_fmt_i   = posit_pkg::POSIT32;
    int_fmt_i   = posit_pkg::INT32;
    op_mod_i    = 1'b0; // assume 0
    flush_i     = 1'b0; // assume no flush
    in_valid_i  = 1'b1; // assume input always valid from upstream (cpu)
    out_ready_i = 1'b1; // assume output always ready from downstream (units)
	rst_ni = 1'b0;
	#10 rst_ni = 1'b1;

    //--------------------------------------------------------- Testcase ----------------------------------------------------------------------

    op_i = posit_pkg::SGNJ; //SGNJ
    rnd_mode_i = posit_pkg::RNE; 
    operands_i = {32'b0, 32'b11001000111000000000000000000000, 32'b01101000111000000000000000000000};  
    #10 display_vals();
		
   	op_i = posit_pkg::SGNJ; //SGNJN
   	rnd_mode_i = posit_pkg::RTZ; 
    operands_i = {32'b0, 32'b11001000111000000000000000000000, 32'b01101000111000000000000000000000};  
    #10 display_vals();

   	op_i = posit_pkg::SGNJ; //SGNJX
   	rnd_mode_i = posit_pkg::RDN; 
    operands_i = {32'b0, 32'b11001000111000000000000000000000, 32'b11101000111000000000000000000000};  
    #10 display_vals();

   	op_i = posit_pkg::MINMAX; //MIN
   	rnd_mode_i = posit_pkg::RNE; 
    operands_i = {32'b0, 32'b01001000111000000000000000000000, 32'b01101000111000000000000000000000};  
    #10 display_vals();

   	op_i = posit_pkg::MINMAX; //MAX
   	rnd_mode_i = posit_pkg::RTZ; 
    operands_i = {32'b0, 32'b01001000111000000000000000000000, 32'b01101000111000000000000000000000};  
    #10 display_vals();

   	op_i = posit_pkg::CMP; //LE
   	rnd_mode_i = posit_pkg::RNE; 
    operands_i = {32'b0, 32'b01111000111000000000000000000000, 32'b01101000111000000000000000000000};  
    #10 display_vals();

   	op_i = posit_pkg::CMP; //LT
   	rnd_mode_i = posit_pkg::RTZ; 
    operands_i = {32'b0, 32'b01001000111000000000000000000000, 32'b01101000111000000000000000000000};  
    #10 display_vals();

   	op_i = posit_pkg::CMP; //EQ
   	rnd_mode_i = posit_pkg::RDN; 
    operands_i = {32'b0, 32'b01001000111000000000000000000000, 32'b01001000111000000000000000000000};  
    #10 display_vals();

   	op_i = posit_pkg::CLASSIFY; //CLASSIFY
   	rnd_mode_i = posit_pkg::RNE; 
    operands_i = {32'b0, 32'b0, 32'b01101000111000000000000000000000};  
    #10 display_vals();

   	op_i = posit_pkg::ADD; //ADD
   	op_mod_i = 1'b0;
    operands_i = {32'b00000001110000110001101111011111, 32'b00000001110111011111001111010001, 32'b0};  
    #10 display_vals();

   	op_i = posit_pkg::ADD; //SUB
   	op_mod_i = 1'b1;
    operands_i = {32'b01001011001100011100011100101010, 32'b01001000111000000000000000000000, 32'b0};  
    #10 display_vals();

   	op_i = posit_pkg::MUL; //MUL
   	op_mod_i = 1'b0;
    operands_i = {32'b0, 32'b01001000111000000000000000000000, 32'b01101000100000000000000110000000};  
    #10 display_vals();

   	op_i = posit_pkg::FMADD; //FMADD
   	op_mod_i = 1'b0;
    operands_i = {32'b01001011001100011100011100101010, 32'b01001000111000000000000000000000, 32'b00111000100000000000000110000000};  
    #10 display_vals();

   	op_i = posit_pkg::FMADD; //FMSUB
   	op_mod_i = 1'b1;
    operands_i = {32'b01001011001100011100011100101010, 32'b01001000111000000000000000000000, 32'b01100000100000000000000110000000};  
    #10 display_vals();

   	op_i = posit_pkg::FNMSUB; //FNMADD 
   	op_mod_i = 1'b1;
    operands_i = {32'b01001011001100011100011100101010, 32'b01001000111000000000000000000000, 32'b01100000100000000000000110000000};  
    #10 display_vals();

   	op_i = posit_pkg::FNMSUB ; //FNMSUB 
   	op_mod_i = 1'b0;
    operands_i = {32'b01001011001100011100011100101010, 32'b01001000111000000000000000000000, 32'b01101000100000000000000110000000};  
    #10 display_vals();

   	op_i = posit_pkg::DIV; //DIV 
    operands_i = {32'b0, 32'b01001000111000000000000000000000, 32'b01011000100000000000000110000000};  
    #10 display_vals();

   	op_i = posit_pkg::SQRT; //SQRT 
    operands_i = {32'b0, 32'b0, 32'b00000001110111011111001111010001};  
    #10 display_vals();
    
    //------------------------------------------------------------ End  -----------------------------------------------------------------------
    #10;
    $stop; 
  end

  // function to convert Posit32 to real 
  function real get_real(input logic signed S, input logic signed [RS:0] K, input logic [ES-1:0] E, input logic [WIDTH-1:0] M, logic zero);
    real M_real;
    if (zero)
      get_real = 0;
    else begin
      M_real   = 1.0 + ((M << 1) / $pow(2, WIDTH)); 
      get_real = (S ? -1.0 : 1.0) * $pow(16.0, K) * $pow(2.0, E) * (M_real);
    end
  endfunction

  // task to display all the values
  task display_vals;
  real val0, val1, val2, valR;
  begin
    val0 = get_real(S0, K0, E0, M0, zero0);
    val1 = get_real(S1, K1, E1, M1, zero1);
    val2 = get_real(S2, K2, E2, M2, zero2);
    valR = get_real(SR, KR, ER, MR, zeroR);
    if(op_i == posit_pkg::CMP || op_i == posit_pkg::CLASSIFY) begin
      $display("IN0= %8f, IN1= %8f, IN2= %8f, Op= %b ,Rnd= %b, Op_mod=%b, Status= %b, Result= %0d",
				val0, val1, val2, op_i, rnd_mode_i, op_mod_i, status_o, result_o);
    end else begin
      $display("IN0= %.10f, IN1= %.10f, IN2= %.10f, Op= %b ,Rnd= %b, Op_mod=%b, Status= %b, Result= %.10f",
				val0, val1, val2, op_i, rnd_mode_i, op_mod_i, status_o, valR);
    end
  end
  endtask

  // Operations
  /*
	0000 - FMADD
	0001 - FMSUB
	0010 - ADD
	0011 - MUL
	0100 - DIV
	0101 - SQRT
	0110 - SGNJ
	0111 - MINMAX
	1000 - CMP
	1001 - CLASSIFY
  */

  // Classification results
  /*
	0001 - zero (1)
	0010 - nar  (2)
	0100 - pos  (4)
	1000 - neg  (8)
 */

endmodule