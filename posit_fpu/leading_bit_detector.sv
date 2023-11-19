module Leading_Bit_Detector 
(
    input  logic signed [31:0] int_input ,
    output integer leading_one_pos,
);

int i;
logic [31:0]   abs_num;

//Do i need to check if the int_input is signed or unsigned integer
always_comb
    begin
        // Default to 32 if no leading one is found (zero case) input是0 该怎么办
        leading_one_pos = 32;

        // Iterate to find the leading one position
        for (int i = 31; i >= 0; i--) begin
            if (abs_num[i] == 1'b1) begin
                leading_one_pos = i;
                break;
            end
        end
    end

endmodule
