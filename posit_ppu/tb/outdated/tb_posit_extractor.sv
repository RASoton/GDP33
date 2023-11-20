
module tb_posit_extractor;

    parameter N = 32;
    parameter ES = 2;
    parameter RS = $clog2(N);

    logic signed [N-1:0] In;

    typedef struct packed {
      logic signed sign;
      logic signed [RS:0] regime;
      logic [ES-1:0] exponent;
      logic [N-1:0] fraction;
      logic signed [N-2:0] remain;
      logic NaR;
      logic zero;
    } posit_result_t;

    posit_result_t extracted_result;

    posit_extractor #(N, ES, RS) uut ();

    initial begin

        In = 32'b01100100001010001100000011010101;
        extracted_result = uut.extract(In);
        display_results(In, extracted_result);

        In = 32'b10010100100110010011001010001101;
        extracted_result = uut.extract(In);
        display_results(In, extracted_result);

        $stop; 
    end

    task display_results(input logic signed [N-1:0] InVal, input posit_result_t result);
        $display("%b | %b | %d | %b | %b",
                 InVal, result.sign, result.regime, result.exponent, result.fraction);
    endtask

endmodule