module posit_cast_multi #(localparam int unsigned WIDTH = 32)
(
  input logic                  clk_i,
  input logic                  rst_ni,
  // Input signals
  input logic [1:0][WIDTH-1:0]     operands_i, // 2 operands
  input posit_pkg::operation_e     op_i,
  input posit_pkg::roundmode_e     rnd_mode_i,
  // Input Handshake
  input  logic                   in_valid_i,
  output logic                   in_ready_o,
  input  logic                   flush_i,
  // Output signals
  output logic [WIDTH-1:0]       result_o,
  output fpnew_pkg::status_t     status_o,
  // Output handshake
  output logic                   out_valid_o,
  input  logic                   out_ready_i,
  // Indication of valid data in flight
  output logic                   busy_o,

   input logic [2:0] opcode,             // Opcode to specify the conversion type
   input logic [31:0] int_input,         // Integer input (signed or unsigned)
   input logic [N-1:0] posit_input,      // Posit input (N-bit wide)
   output logic [31:0] int_output,       // Integer output (signed or unsigned)
   output logic [N-1:0] posit_output     // Posit output (N-bit wide)
)


    // Define opcodes for different instructions
    localparam [2:0] SIGNED_INT_TO_POSIT = 3'b000;   // Opcode for signed integer to posit conversion
    localparam [2:0] UNSIGNED_INT_TO_POSIT = 3'b001; // Opcode for unsigned integer to posit conversion
    localparam [2:0] POSIT_TO_SIGNED_INT = 3'b010;   // Opcode for posit to signed integer conversion
    localparam [2:0] POSIT_TO_UNSIGNED_INT = 3'b011; // Opcode for posit to unsigned integer conversion

logic signed_int,
logic unsigned_int,
logic E,

logic [N-1:0] IN1, IN2,
logic signed[RS+ES:0]LE_O,
logic [ES-1:0] E_O,
logic [N-1:0] Add_Mant_N,
logic signed [RS:0] R_O,
logic Sign,
logic inf, zero,

int i;
logic [31:0]   abs_num,

always_comb begin : 

  E = (Regime*(2**(ES))) + Exponent
end

module Leading_Bit_Detector 
(
    input  logic signed [31:0] int_input ,
    output integer leading_one_pos,
);

//Do i need to check if the int_input is signed or unsigned integer
always_comb
    begin
        // Iterate to find the leading one position
        for (int i = 31; i >= 0; i--) begin
            if (abs_num[i] == 1'b1) begin
                leading_one_pos = i;
                break;
            end
        end
    end

endmodule

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

module sign_detector(
    input logic signed [31:0] int_input,
    output logic Sign
);

    // Determine the sign
    always_comb begin
        // If MSB is 1, it's negative
        Sign= int_input[31];
    end

endmodule

logic shift_amount,
logic temp_int_input,

always_comb begin
        case (opcode)
        //FCVT.S.W
        SIGNED_INT_TO_POSIT: begin
        if int_input = bit [31:0] value = 1 << 31;
            posit_output = posit_pkg::posit_NAR;
        else if (leading_one_pos)
             shift_amount = 31 - leading_one_pos +1;
             Add_Mant_N = input_integer << shift_amount; //shift to find out fraction part
             LE_O = leading_one_pos - 1;
             E_O =  leading_one_pos - 1[1:0];
             R_O =  leading_one_pos - 1[31:2]; //use the rounding module to get temp_output
             else
             posit_output = 0;
        //sign = number 31, 1 for negative 0 for positive
        if(Sign)
        posit_output = -temp_output1;
        else
        posit_output = temp_output1;        
        end

        //FCVT.S.WU
        UNSIGNED_INT_TO_POSIT: begin
        if int_input = bit [31:0] value = 1 << 31;
            posit_output = posit_pkg::posit_NAR ;
        else if (leading_one_pos)
             shift_amount = 31 - leading_one_pos +1;
             Add_Mant_N = input_integer << shift_amount; //shift to find out fraction part
             LE_O = leading_one_pos - 1;
             E_O =  leading_one_pos - 1[1:0];
             R_O =  leading_one_pos - 1[31:2];
             else
             posit_output = 0; 
        //sign = always positive
        posit_output = temp_output;     
        end

        //FCVT.W.S
        POSIT_TO_SIGNED_INT: begin 
        if -31< E < 31
          begin
          if E > 0
          E = E[N:0] << shift;
          else
          E = E[N:0] >> shift;
          end
          posit_bf_round = (~1)**Sign *(2**2**ES)**k * 2**Exponent *(1+Mantissa);
          // rounding
          int_output = posit_af_round;
          else
          int_output = bit [31:0] value = 1 << 31;
        end

        ////FCVT.WU.S    
        POSIT_TO_UNSIGNED_INT: begin
        if posit < 0
        posit_out = 0;
        else if E >32
             int_output = bit [31:0] value = 1 << 31;
             else
             begin
             if E > 0
             E = E[N:0] << shift;
             else
             E = E[N:0] >> shift;
             end
             posit_bf_round = (~1)**Sign *(2**2**ES)**k * 2**Exponent *(1+Mantissa);
             //rounding
             int_output = posit_af_round;   
            end
        endcase
    end


endmodule
