module tb_posit_sqrt;

  localparam N = 32;
  localparam ES = 2;
  localparam RS = $clog2(N);

  logic signed [N-1:0] posit_input;
  logic signed [N-1:0] posit_output;

  logic signed sign;
  logic signed [RS:0] regime;
  logic [ES-1:0] exponent;
  logic [N-1:0] mantissa;
  logic signed [N-2:0] InRemain;
  logic NaR;
  logic zero;

  logic [N-1:0] sqrt_result;

  posit_extraction extractor
  (
   .In(posit_input),
   .Sign(sign),
   .k(regime),
   .Exponent(exponent),
   .Mantissa(mantissa),
   .InRemain(InRemain),
   .NaR(NaR),
   .zero(zero)
  );

  logic [ES-1:0] E_O;
  logic signed [RS+4:0] R_O;
  logic [2*N-1:0] Sqrt_Mant;
  logic sign_Exponent_O;

  posit_sqrt_NR sqrt
  (
   .Enable (1'b1),
   .Sign (sign),
   .Regime (regime),
   .Exponent (exponent),
   .Mantissa (mantissa),
   .E_O (E_O),
   .R_O (R_O),
   .Sqrt_Mant (Sqrt_Mant),
   .sign_Exponent_O (sign_Exponent_O)
  );

  posit_rounding rnd
  (
   .E_O (E_O),
   .Comp_Mant_N (Sqrt_Mant),
   .R_O (R_O),
   .sign_Exponent_O (sign_Exponent_O),
   .Sign (sign),
   .NaR (NaR),
   .zero (zero),
   .OUT (sqrt_result)
  );

  integer input_fd, output_fd, scan_file;

  initial begin
    // Take note that zero and NaR are handled in posit_divsqrt.sv
    input_fd = $fopen("/ppu/test/uvm_test/sqrt_test/sqrt_test.txt", "r");
    if (input_fd == 0) begin
      $display("Failed to open input file.");
      $finish;
    end

    output_fd = $fopen("/ppu/test/uvm_test/sqrt_test/sqrt_output.txt", "w");
    if (output_fd == 0) begin
      $display("Failed to open output file.");
      $finish;
    end

    while (!$feof(input_fd)) begin
      scan_file = $fscanf(input_fd, "%b\n", posit_input);
      if (scan_file != 1) begin
        $display("Failed to read a line from the input file.");
        continue;
      end

      #10; 

      posit_output = sqrt_result; 
      //$display("sign=%b, regime=%b, exponent=%b, mantissa=%b\n", sign, R_O, E_O, Sqrt_Mant<<1);
      //$display("R_O=%d, sign=%b", R_O, sign_Exponent_O);
      $fwrite(output_fd, "%b\n", posit_output);
    end

    $fclose(input_fd);
    $fclose(output_fd);

  end
endmodule
