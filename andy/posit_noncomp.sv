module posit_noncomp #(
    localparam int unsigned WIDTH = 32
) (
  input logic                  clk_i,
  input logic                  rst_ni,
  // Input signals
  input logic [1:0][WIDTH-1:0]     operands_i, // 2 operands
  input posit_pkg::operation_e     op_i,
  input posit_pkg::roundmode_e     rnd_mode_i,
  input posit_pkg::signinject_e   //sign inect
  input logic                      signinject_e
  // Input Handshake
  input  logic                     in_valid_i,
  output logic                     in_ready_o,
  input  logic                     flush_i,
  // Output signals
  output logic [WIDTH-1:0]         result_o,
  output posit_pkg::status_t       status_o,
  output logic [N-1:0]             sign_result // sign inject
  output logic [31:0]              minmax_result;// min max
  // Output handshake
  output logic                     out_valid_o,
  input  logic                     out_ready_i,
  // Indication of valid data in flight
  output logic                     busy_o
);

logic invalid_input;
logic [31:0] compare_result;
logic signed [WIDTH-1:0] src1;
logic signed [WIDTH-1:0] src2;

logic [31:0] sign_result;

logic equal;
logic less;

assign src1 = operands_i[0];
assign src2 = operands_i[1];
assign invalid_input = (posit_pkg::POSIT_NAR == operands_i[0]) || (posit_pkg::POSIT_NAR == operands_i[1]);

always_comb
begin : Comp

  equal = (src1 == src2);
  less = (src1 < src2);

  case (rnd_mode_i)
    posit_pkg::RNE: begin compare_result = 32'(unsigned'(equal | less)); end
    posit_pkg::RTZ: begin compare_result = 32'(unsigned'(less)); end
    posit_pkg::RDN: begin compare_result = 32'(unsigned'(equal)); end

    default : compare_result = 32'b0;
  endcase
end

always_comb
begin : Output
  status_o = '0;
  status_o.NV = invalid_input;
  case (op_i)
    posit_pkg::SGN: begin result_o = sign_result; end
    posit_pkg::CMP: begin result_o = compare_result; end
    default: result_o = 32'b0;
  endcase
end
endmodule

module posit_sign_inject #(N = 32)
(
    input logic [N-1:0] src1, // First operand
    input logic [N-1:0] src2, // Second operand 
    input posit_pkg::operation_e     op_i,
    input posit_pkg::signinject_e    
    input logic [1:0] op,     // Control signal: 0 for SGNJ, 1 for SGNJN, 2 for SGNJX
    output logic [N-1:0] sign_result // Result
);

// sign injection


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


// Min max

assign invalid_input = (posit_pkg::POSIT_NAR == posit_a) || (posit_pkg::POSIT_NAR == posit_b);
assign src1 = posit_a;
assign src2 = posit_b;

logic min
logic max
logic invalid_input
posit_pkg::status_t        minmax_status;

always_comb
begin
 min =  (src1 < src2) ? src1 : src2;
 max =  (src1 > src2) ? src1 : src2;;

 // Default assignment
 minmax_status = '0;

 // Both NaR inputs cause a NaR output
 if (src1 == posit_pkg::posit_NAR && src2 == posit_pkg::posit_NAR)
   minmax_result = invalid_input
 // If one operand is NaR, the non-NaR operand is returned
 else if (src1 == posit_pkg::posit_NAR) minmax_result = posit_b;
 else if (src2 == posit_pkg::posit_NAR) minmax_result = posit_a;
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
