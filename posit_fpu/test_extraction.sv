
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

    tb_In = 32'b01100100001010001100000011010101;  
    #10;

    tb_In = 32'b10010100100110010011001010001101;  
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