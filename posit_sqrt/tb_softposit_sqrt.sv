
module tb_softposit_sqrt;

  parameter N = 32;
  parameter ES = 2;
  parameter RS = $clog2(N);

  logic [N-1:0] posit_input;
  logic [N-1:0] posit_output;

  softposit_sqrt #(
    .N(N),
    .ES(ES),
    .RS(RS)
  ) mut (
    .value(posit_input),
    .result(posit_output)
  );

  integer input_fd, output_fd, scan_file;

  initial begin
        input_fd = $fopen("C:/Users/sywon/OneDrive/Desktop/sqrt_test/sqrt_test.txt", "r");
        if (input_fd == 0) begin
            $display("Failed to open input file.");
            $finish;
        end

        output_fd = $fopen("C:/Users/sywon/OneDrive/Desktop/sqrt_test/softposit_sqrt_output.txt", "w");
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

            $fwrite(output_fd, "%b\n", posit_output);
        end

        $fclose(input_fd);
        $fclose(output_fd);

  end

endmodule