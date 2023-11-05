module tb_posit_sqrt;

    parameter N = 32;
    parameter ES = 2;
    parameter RS = $clog2(N);

    logic signed [N-1:0] posit_input;
    logic signed [N-1:0] posit_output;

    logic signed sign;
    logic signed [RS:0] regime;
    logic [ES-1:0] exponent;
    logic [N-1:0] fraction;
    logic signed [N-2:0] InRemain;
    logic NaR;
    logic zero;

    logic [N-1:0] sqrt_result;

    posit_extraction #(.N(N), .ES(ES), .RS(RS)) u0 (
      .In(posit_input),
      .Sign(sign),
      .k(regime),
      .Exponent(exponent),
      .Mantissa(fraction),
      .InRemain(InRemain),
      .inf(NaR),
      .zero(zero)
    );

    posit_sqrt #(N, ES, RS) sqrt(
        .sign(sign), 
        .regime(regime), 
        .exponent(exponent), 
        .fraction(fraction), 
        .result(sqrt_result)
    );

    integer input_fd, output_fd, scan_file;

    initial begin

        input_fd = $fopen("C:/Users/sywon/OneDrive/Desktop/sqrt_test/sqrt_test.txt", "r");
        if (input_fd == 0) begin
            $display("Failed to open input file.");
            $finish;
        end

        output_fd = $fopen("C:/Users/sywon/OneDrive/Desktop/sqrt_test/sqrt_output.txt", "w");
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
endmodule
