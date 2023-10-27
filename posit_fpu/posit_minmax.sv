module posit_minmax #(
    localparam unsigned int WIDTH = 32
) (
  input logic [1:0][WIDTH-1:0]     operands_i, // 2 operands
  input posit_pkg::operation_e     op_i,
  input posit_pkg::status_t        minmax_status;
  input posit_pkg::roundmode_e     rnd_mode_i,
  output logic minmax_result;
        logic               minmax_extension_bit;
);


  signed logic [WIDTH-1:0] src1;
  signed logic [WIDTH-1:0] src2;

always_comb begin : min_max
// Default assignment
minmax_status = '0;

invalid_input =

    // Both NaN inputs cause a NaN output
    if (info_a.is_nan && info_b.is_nan)
      minmax_result = '{sign: 1'b0, exponent: '1, mantissa: 2**(MAN_BITS-1)}; // canonical qNaN
    // If one operand is NaN, the non-NaN operand is returned
    else if (info_a.is_nan) minmax_result = operand_b;
    else if (info_b.is_nan) minmax_result = operand_a;
    // Otherwise decide according to the operation
    else begin
      unique case (inp_pipe_rnd_mode_q[NUM_INP_REGS])
        fpnew_pkg::RNE: minmax_result = operand_a_smaller ? operand_a : operand_b; // MIN
        fpnew_pkg::RTZ: minmax_result = operand_a_smaller ? operand_b : operand_a; // MAX
        default: minmax_result = '{default: fpnew_pkg::DONT_CARE}; // don't care
      endcase
    end
    
  assign minmax_extension_bit = 1'b1; // NaN-box as result is always a float value



end
endmodule

