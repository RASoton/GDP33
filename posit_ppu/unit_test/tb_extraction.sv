
module tb_extraction;
  parameter N = 32;
  parameter ES = 2;
  parameter RS = $clog2(N);

  logic signed [N-1:0] In;
  logic signed Sign;
  logic signed [RS:0] k;
  logic [ES-1:0] Exponent;
  logic [N-1:0] Mantissa;
  logic signed [N-2:0] InRemain;
  logic NaR;
  logic zero;

  posit_extraction u0 (.*);

  initial begin

    In = 32'b0;  // zero
    #10;

    In = 32'b01000000000000000000000000000000;  // one
    #10;

    In = 32'b11111111111111111111111111111111;  // Largest 
    #10;

    In = 32'b01101000000000001000100001000000;  
    #10;

    In = 32'b10000000000000000000000000000000;  // NaR
    #10;

    $stop;
  end

	initial begin
		$monitor("IN=%b, Sign=%b, Regime=%b, Exponent=%b, Mantissa=%b, Zero=%b, NaR=%b", In, Sign, k, Exponent, Mantissa, zero, NaR);
	end

endmodule