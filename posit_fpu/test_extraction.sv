
module test_extraction;
  parameter N = 32;
  parameter ES = 2;
  parameter RS = $clog2(N);

  logic signed [N-1:0] tb_In;
  logic signed tb_Sign;
  logic signed [RS:0] tb_k;
  logic [ES-1:0] tb_Exponent;
  logic [N-1:0] tb_Mantissa;
  logic signed [N-2:0] tb_InRemain;
  logic tb_inf;
  logic tb_zero;

  posit_extraction #(.N(N), .ES(ES), .RS(RS)) u0 (
    .In(tb_In),
    .Sign(tb_Sign),
    .k(tb_k),
    .Exponent(tb_Exponent),
    .Mantissa(tb_Mantissa),
    .InRemain(tb_InRemain),
    .inf(tb_inf),
    .zero(tb_zero)
  );

  initial begin

    tb_In = 32'b01010101010101010101010101010101;  
    #10;

    tb_In = 32'b01110111010101010101010111111111;  
    #10;

    tb_In = 32'b11111111111111111111111111111111;  
    #10;

    tb_In = 32'b00000000000000000000000000000000;  
    #10;

    tb_In = 32'b10000000000000000000000000000000;  
    #10;

    $finish;
  end

endmodule