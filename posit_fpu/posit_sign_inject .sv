module posit_sign_inject #(N = 32)
(
    input logic [N-1:0] posit_a, // First operand
    input logic [N-1:0] posit_b, // Second operand (source of the sign)
    input posit_pkg::operation_e     op_i, 
    input logic [1:0] op,     // Control signal: 0 for SGNJ, 1 for SGNJN, 2 for SGNJX
    output logic [N-1:0] posit_out // Result
);

always_ff @(*) 
begin
    logic sign_a;
    logic sign_b;
    logic result_sign;
    sign_a = posit_a[N-1];
    sign_b = posit_b[N-1];  // Extract the sign bits

    case (operation)
        2'b00:  //  SGNJ
        begin
        if(sign_a ^ sign_b)  
            posit_out = posit_a;   
        else
            posit_out = -posit_a;
        end
        2'b01:  // SGNJN
        begin
            if(sign_a ^ ~sign_b)    
                posit_out = -posit_a;   
            else
                posit_out = posit_a;
        end            
        2'b10: 
        begin   // SGNJX
            if(sign_b)  // 如果b是负的
                posit_out = -posit_a;   //翻转
            else
                posit_out = posit_a;
        end                                       
        default: posit_out = posit_a;            // Default case should not occur, but just in case revert to SGNJ
    endcase
end
endmodule