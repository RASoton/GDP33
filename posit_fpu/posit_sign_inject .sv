module posit_sign_inject #(N = 32)
(
    input logic [N-1:0] src1, // First operand
    input logic [N-1:0] src2, // Second operand 
    input posit_pkg::operation_e     op_i,
    input posit_pkg::signinject_e    
    input logic [1:0] op,     // Control signal: 0 for SGNJ, 1 for SGNJN, 2 for SGNJX
    output logic [N-1:0] sign_result // Result
);

always_comb
begin
    logic sign_a;
    logic sign_b;
    logic result_sign;
    sign_a = src1[N-1];
    sign_b = src2[N-1];  // Extract the sign bits

    case (operation)
        2'b00:  //  SGNJ
        if(sign_a ^ sign_b)  
            sign_result = src1;   
        else
            sign_result = -src1;
        2'b01:  // SGNJN
            if(sign_a ^ ~sign_b)    
                sign_result = -src1;   
            else
                sign_result = src1;           
        2'b10:    // SGNJX
            if(sign_b)  // 
                sign_result = -src1;   //
            else
                sign_result = src1;                                       
        default: sign_result = src1;            // Default case should not occur, but just in case revert to SGNJ
    endcase
end
endmodule