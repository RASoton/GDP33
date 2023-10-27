module posit_sign_inject #(
    localparam unsigned int WIDTH = 32  // Width of the posit
)(
    input logic [WIDTH-1:0] posit_a, // First operand
    input logic [WIDTH-1:0] posit_b, // Second operand (source of the sign)
    input posit_pkg::operation_e     op_i, 
    input logic [1:0] operation,     // Control signal: 0 for SGNJ, 1 for SGNJN, 2 for SGNJX
    output logic [WIDTH-1:0] posit_out // Result
);

always_ff @(*) begin
    logic sign_a;
    logic sign_b;
    logic result_sign;
    sign_a = posit_a[WIDTH-1];
    sign_b = posit_b[WIDTH-1];// Extract the sign bits
    result_sign = sign_b; // Default to SGNJ operation (just in case)

    case (operation)
        2'b00: result_sign = sign_b;              // SGNJ
        2'b01: result_sign = ~sign_b;             // SGNJN
        2'b10: result_sign = sign_a ^ sign_b;     // SGNJX
                                                  // Perform the selected sign injection operation
        default: result_sign = sign_b;            // Default case should not occur, but just in case revert to SGNJ
    endcase

    posit_out = {result_sign, posit_a[WIDTH-2:0]}; // Replace the sign bit in posit_a with result_sign // Construct the output posit value with the new sign
end

endmodule