
module tb_posit_operations_extended;

    parameter WIDTH = 32;
    parameter ES = 2;

    logic [WIDTH-1:0] In;
    logic [WIDTH-1:0] Out;

    logic [WIDTH-1:0] posit_input;
    logic [WIDTH-1:0] posit_output;
    logic sign;
    real decimal_input;

    posit_operations_extended uut (.*);

    initial begin

        // Test the negate function
        posit_input = 32'b01000000000000000000000000000000; 
        $display("Negate result: %b", uut.negate(posit_input));

        // Test the abs function
        posit_input = 32'b11000000000010001000100010000000; 
        $display("Abs result: %b", uut.abs(posit_input));

        // Test the get_sign function
        posit_input = 32'b11000000000000000000000000000000; 
        $display("Sign result: %b", uut.get_sign(posit_input));

        // Test the encode_posit function
        decimal_input = 3.14; 
        $display("Encode result: %b", uut.encode_posit(decimal_input));

        $finish;
    end

endmodule