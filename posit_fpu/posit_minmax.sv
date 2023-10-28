module posit_minmax #(
    localparam unsigned int WIDTH = 32 //(N = 32)
) (
  input logic [N-1:0] posit_a, // First operand
  input logic [N-1:0] posit_b, // Second operand 
  input posit_pkg::roundmode_e     rnd_mode_i,
  output logic minmax_result;
);

logic [31:0] invalid_input;
logic signed [WIDTH-1:0] src1; 
logic signed [WIDTH-1:0] src2;

logic min
logic max

posit_pkg::status_t        minmax_status;

assign invalid_input = (posit_pkg::POSIT_NAR == posit_a) || (posit_pkg::POSIT_NAR == posit_b);
assign src1 = posit_a;
assign src2 = posit_b;

always_ff @(*) 
begin : min_max

 min = (src1 < src2);
 max = (src1 > src2);

 // Default assignment
 minmax_status = '0;

 // Both NaR inputs cause a NaR output
 if (info_o[a].is_NaR && info_o[b].is_NaR)
   minmax_result = invalid_input
 // If one operand is NaR, the non-NaR operand is returned
 else if (info_o[a].is_NaR) minmax_result = posit_b;
 else if (info_o[b].is_NaR) minmax_result = posit_a;
 // Otherwise decide according to the operation
 else begin
   unique case (rnd_mode_i)
     posit_pkg::RNE: begin minmax_result = 32'(unsigned'(max)); end // Max
     posit_pkg::RTZ: begin minmax_result = 32'(unsigned'(min)); end // Min
     default: minmax_result = '{default: posit_pkg::DONT_CARE}; // don't care
   endcase
end

end
endmodule



