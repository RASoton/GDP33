module tb_posit_sqrt;

    parameter N = 32;
    parameter ES = 2;
    parameter RS = $clog2(N);

    logic signed [N-1:0] posit_input;

    logic signed sign;
    logic signed [RS:0] regime;
    logic [ES-1:0] exponent;
    logic [N-1:0] fraction;
    logic signed [N-2:0] InRemain;
    logic NaR1, NaR;
    logic zero;
  	logic [ES-1:0] E_O;
	logic [RS+4:0] R_O;
	logic [2*N-1:0] Sqrt_Mant;
  	logic [RS+ES+4:0] Total_EO;
	logic [N-1:0] result;
	logic enable_sqrt, enable_rnd, done_sqrt, done_rnd;

    posit_extraction u0 (
      .In(posit_input),
      .Sign(sign),
      .k(regime),
      .Exponent(exponent),
      .Mantissa(fraction),
      .InRemain(InRemain),
      .NaR(NaR1),
      .zero(zero)
    );

    posit_sqrt sqrt(
		.Enable(enable_sqrt),
		.Done(done_sqrt),
        .Sign(sign), 
        .Regime(regime), 
        .Exponent(exponent), 
        .Mantissa(fraction), 
		.E_O(E_O),
		.R_O(R_O),
		.Total_EO(Total_EO),
		.Sqrt_Mant(Sqrt_Mant),
		.NaR(NaR)
    );

	posit_rounding rnd(
		.Enable(enable_rnd),
		.Done(done_rnd),
		.Sign(sign),
		.R_O(R_O),
		.E_O(E_O),
		.Mant(Sqrt_Mant),
		.Total_EO(Total_EO),
		.NaR(NaR),
		.zero(zero),
		.OUT(result)
	);

    integer input_fd, output_fd, scan_file;

    initial begin
/*
        input_fd = $fopen("C:/Users/sywon/OneDrive/Desktop/test/test_range_sqrt.txt", "r");
        if (input_fd == 0) begin
            $display("Failed to open input file.");
            $finish;
        end

        output_fd = $fopen("C:/Users/sywon/OneDrive/Desktop/test/sqrt_output.txt", "w");
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

            if (NaR) begin
                posit_output = {1'b1, {(N-1){1'b0}}}; 
            end else if (zero) begin
                posit_output = 0; 
            end else begin
                posit_output = sqrt_result; 
            end

            $fwrite(output_fd, "%b\n", posit_output);
        end

        $fclose(input_fd);
        $fclose(output_fd);

	end
*/
		enable_sqrt = 1'b1;
		enable_rnd = 1'b1;
		posit_input = 32'h0;
		#10;
		posit_input = 32'h80000000;
		#10;
		posit_input = 32'b01101011001100011100011100101010;
		#10;
		posit_input = 32'b01111111111011000111111101001001;
		#10;

    end

	initial begin
		$monitor("Input=%b, Sign=%b, R_O=%b, E_O=%b, Sqrt_Mant=%b, Total_EO=%b, Result=%b",
				  posit_input, sign, R_O, E_O, Sqrt_Mant, Total_EO, result);
	end

endmodule
