module rounding(
    input  logic [31:0] posit_bf_round,  // 32-bit input
    output logic [31:0] posit_af_round  // Rounded 32-bit output 
);

    logic [63:0] temp_num;

    assign temp_num = posit_bf_round << 32;

    always_comb begin
        if (temp_num[31]) begin
            posit_af_round = temp_num[63:32] + 1;
        end 
        else begin
            posit_af_round = temp_num[63:32];
        end
    end

endmodule