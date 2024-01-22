// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

// Language: SystemVerilog
// Description: posit-based addition and multiplication related module

module posit_fma #(
  parameter posit_pkg::posit_format_e   pFormat    = posit_pkg::posit_format_e'(0),
  localparam int unsigned WIDTH  = posit_pkg::posit_width(pFormat), 
  localparam int unsigned ES = posit_pkg::exp_bits(pFormat), 
  localparam int unsigned RS = $clog2(WIDTH)
) (
  input logic                      clk_i,
  input logic                      rst_ni,
  // Input signals
  input logic [2:0][WIDTH-1:0]     operands_i, // 3 operands
  input posit_pkg::operation_e     op_i,
  input logic                      op_mod_i,
  input logic                      tag_i,
  // Input Handshake
  input  logic                     in_valid_i,
  output logic                     in_ready_o,
  input  logic                     flush_i,
  // Output signals
  output logic [WIDTH-1:0]         result_o,
  output posit_pkg::status_t       status_o,
  output logic                     tag_o,
  // Output handshake
  output logic                     out_valid_o,
  input  logic                     out_ready_i,
  // Indication of valid data in flight
  output logic                     busy_o
);

  // -----------------
  // Input processing
  // -----------------
  logic [WIDTH-1:0] operand_a, operand_b, operand_c;
  posit_pkg::status_t status;
  logic op_N;

  // Operation selection and operand adjustment
  // | \c op_q  | \c op_mod_q | Operation Adjustment
  // |:--------:|:-----------:|---------------------
  // | FMADD    | \c 0        | FMADD: none
  // | FMADD    | \c 1        | FMSUB: Invert sign of operand C
  // | FNMSUB   | \c 0        | FNMSUB: Invert sign of operand A
  // | FNMSUB   | \c 1        | FNMADD: Invert sign of operands A and C
  // | ADD      | \c 0        | ADD: Set operand A to +1.0
  // | ADD      | \c 1        | SUB: Set operand A to +1.0, invert sign of operand C
  // | MUL      | \c 0        | MUL: Set operand C to 0.0 
  // | *others* | \c -        | *invalid*
  // \note \c op_mod_q always inverts the sign of the addend.

  always_comb begin : op_select
    // Default assignments - packing-order-agnostic
    operand_a = operands_i[0];
    operand_b = operands_i[1];
    operand_c = operands_i[2];
    op_N = 0;
	
    if(op_mod_i)
      operand_c = -operand_c;
	  
    unique case (op_i)
      posit_pkg::FMADD: ;                 
      posit_pkg::FNMSUB: op_N = 1;
      posit_pkg::ADD: operand_a = 32'h40000000;   // Set multiplicand to +1 
      posit_pkg::MUL: operand_c = '0;             // Set addend to 0
   
      default: begin // propagate don't cares
        operand_a  = '{default: posit_pkg::DONT_CARE};
        operand_b  = '{default: posit_pkg::DONT_CARE};
        operand_c  = '{default: posit_pkg::DONT_CARE};
      end
    endcase
  end

  // ----------------------------
  // Posit Components Extraction
  // ----------------------------
  logic signed Sign1, Sign2, Sign3;
  logic signed [RS:0] k1, k2, k3;
  logic [ES-1:0] Exponent1, Exponent2, Exponent3;
  logic [WIDTH-1:0] Mantissa1, Mantissa2, Mantissa3;
  logic signed [WIDTH-2:0] InRemain1, InRemain2, InRemain3;
  logic NaR1, NaR2, NaR3, zero1, zero2, zero3;
  logic [WIDTH-1:0] result;
  
  posit_extraction #(.pFormat(pFormat)) Extract_IN1 (.In(operand_a), .Sign(Sign1), .k(k1), .Exponent(Exponent1), .Mantissa(Mantissa1), .InRemain(InRemain1), .NaR(NaR1), .zero(zero1));
  posit_extraction #(.pFormat(pFormat)) Extract_IN2 (.In(operand_b), .Sign(Sign2), .k(k2), .Exponent(Exponent2), .Mantissa(Mantissa2), .InRemain(InRemain2), .NaR(NaR2), .zero(zero2));
  posit_extraction #(.pFormat(pFormat)) Extract_IN3 (.In(operand_c), .Sign(Sign3), .k(k3), .Exponent(Exponent3), .Mantissa(Mantissa3), .InRemain(InRemain3), .NaR(NaR3), .zero(zero3));

  // ----------------------
  // Algorithms Start Here
  // ----------------------
  logic LS, op, Greater_Than;
  logic inf_temp, zero_temp, Sign_temp;
  logic [2*WIDTH-1:0] Mult_Mant;
  logic [2*WIDTH-1:0] Mult_Mant_N, sft_mant3;
  logic signed [RS+2:0]sumE_Ovf;
  logic [ES:0] sumE, sumE_temp;  // 1 more bit then Exponent for Ovf
  logic signed [RS+2:0] R_O_temp, R_O_mult, sumR_temp;
  logic [ES-1:0] E_O_mult;
  logic [RS+2:0] LR, SR;
  logic [ES-1:0]LE, SE;
  logic [2*WIDTH-1:0]LM, SM;
  // logic [2*WIDTH-1:0] LM1, SM1;
  //  exponent difference 
  logic signed [RS+2:0] R_diff;
  logic [WIDTH-1:0] E_diff;
  // shifting accordingly and mantissa addition
  logic [2*WIDTH-1:0]SM_sft;
  logic [3*WIDTH-1:0]SM_sft2;
  logic [2*WIDTH:0] Add_Mant;
  logic [2*WIDTH-1:0] Add_Mant_sft;
  // post composition
  logic [WIDTH-1:0] LBD_in;
  logic Mant_Ovf;
  logic signed [RS:0] shift;
  logic [ES+RS+1:0] LE_ON;
  logic [2*WIDTH-1:0] FMA_Mant_N;
  logic [ES+RS+1:0] LE_O;
  logic [ES-1:0] E_O;
  logic signed [RS+4:0] R_O, sumR;
  logic NaR, zero, Sign;
  logic check; 
  logic signed [RS:0] EP;
  logic sign_Exponent_O;

  // -------------------------
  // Multiplication & Addition
  // -------------------------
  always_comb begin
    // mult part
    // check infinity and zero
    inf_temp = NaR1 | NaR2;
    zero_temp = zero1 | zero2;

    // --------------------------
    // Multiplication Arithmetic
    // --------------------------

    Sign_temp = (Sign1 ^ Sign2) ^ op_N;

    // Mantissa Multiplication Handling
    Mult_Mant = Mantissa1 * Mantissa2;

    if(Mult_Mant[2*WIDTH-1])
    	Mult_Mant_N = Mult_Mant ;
    else
    	Mult_Mant_N = Mult_Mant << 1;

    if(sumR[RS+2])
    	sumE_temp = Exponent1+Exponent2 + Mult_Mant[2*WIDTH-1];
    else
    	sumE_temp = Exponent1+Exponent2 + Mult_Mant[2*WIDTH-1];

    sumE_Ovf = {{RS+1{1'b0}}, sumE_temp[ES]};
    sumR_temp = k1+k2+sumE_Ovf;
    if(sumR[RS+2]) begin            // negtaive exponent
      E_O_mult = sumE_temp[ES-1:0];
      // R_O_mult = -sumR_temp;
    end
    else begin                      // positive exponent
      E_O_mult = sumE_temp[ES-1:0];
      // R_O_mult = sumR_temp + 1'b1;
    end

    // --------------------------
    // Addition Arithmetic
    // --------------------------

    NaR = inf_temp | NaR3;
    zero = zero_temp & zero3;
    op = Sign_temp ~^ Sign3;

    // sft_mant3 = Mantissa3 << WIDTH;
    sft_mant3 = {Mantissa3, {WIDTH{1'b0}}};

    if(sumR_temp > k3)
      Greater_Than = 1;
    else if (sumR_temp == k3 && E_O_mult > Exponent3)
      Greater_Than = 1;
    else if (sumR_temp == k3 && E_O_mult == Exponent3 && Mult_Mant_N > sft_mant3)
      Greater_Than = 1;
    else
      Greater_Than = 0;
    
    // Assign components to corresponding logic, L - Large S - Small
    LS  = Greater_Than ? Sign_temp : Sign3;
    LR  = Greater_Than ? sumR_temp : k3;
    LE  = Greater_Than ? E_O_mult : Exponent3;
    LM  = Greater_Than ? Mult_Mant_N : sft_mant3; // MSB for overflow detection
    SR  = Greater_Than ? k3 : sumR_temp;
    SE  = Greater_Than ? Exponent3 : E_O_mult;
    SM  = Greater_Than ? sft_mant3 : Mult_Mant_N;

    Sign = LS;

    // Mantissa Addition Handling
    // find the regime difference
    R_diff = LR - SR;

    // total exponent difference
    E_diff = (R_diff*(2**(ES))) + (LE - SE); 
    // LM1 = {LM, {WIDTH{1'b0}}};
    // SM1 = {SM, {WIDTH{1'b0}}};

    // if(E_diff > 64)
    //     SM_sft = SM1 >> 64;
    // else
    //     SM_sft = SM1 >> E_diff;

    if(E_diff > 2*WIDTH)
        SM_sft2 = {SM, {WIDTH{1'b0}}} >> 2*WIDTH;
    else
        SM_sft2 = {SM, {WIDTH{1'b0}}} >> E_diff;

    SM_sft = {SM_sft2[3*WIDTH-1:WIDTH+1], |SM_sft2[WIDTH:0]};

    if(op)
        Add_Mant = LM + SM_sft;
    else
        Add_Mant = LM - SM_sft;
        
    Mant_Ovf = Add_Mant[2*WIDTH];

    // set zero flag when subtracting two identical numbers
    if(LR == SR && LM == SM && LE == SE && ~op)
      zero = 1;
    else
      zero = zero;
    
    // (MSB OR 2nd MSB) bit since LBD_IN is for leading bit
    LBD_in = {(Add_Mant[2*WIDTH] | Add_Mant[2*WIDTH-1]), Add_Mant[2*WIDTH-2:WIDTH]}; 

    // ---------------------
    // Leading Bit Detection
    // ---------------------
    check = 1; 
    shift = '0;
    // EndPosition = EndPosition + 1'b1; // initial EP starts from InRemain[1] as InRemain[0] is RC
    for(int i = 1; i < WIDTH; i++) 
    	begin
      /* 
      compareing MSB of InRemain to the follwing bits
             until the different bit turns up    
      */
      if (check != LBD_in[(WIDTH-i)])
      	shift = shift + 1'b1;
      else 
        break;
		end

    if(Mant_Ovf) begin
    	Add_Mant_sft = Add_Mant[2*WIDTH:1] << shift;
    end else begin
      Add_Mant_sft = Add_Mant[2*WIDTH-1:0] << shift;           
    end
    FMA_Mant_N = Add_Mant_sft;
    // Add_Mant_N[0] = Add_Mant_N[0]|Add_Mant[0];

    // ------------------------------
    // Post Composition for Rounding
    // ------------------------------

    // Compute regime and exponent of final result  
    /* 
    Output exponent is mainly based on larger input
    also taking overflow and left shift into account
    */
    LE_O = {LR, LE} + Mant_Ovf - shift; 
    sign_Exponent_O = LE_O[RS+ES+1];
    if (LE_O[RS+ES+1])    // -ve exponent
        LE_ON = -LE_O;
    else                  // +ve exponent
        LE_ON = LE_O;

    if (LE_O[ES+RS+1] & |(LE_ON[ES-1:0])) // if -ve LE_O, last ES bits in LE_ON are not '0
        E_O = (1<<ES)-LE_ON[ES-1:0];
    else
        E_O = LE_ON[ES-1:0];

    if (~LE_O[ES+RS+1]) // +ve exponent, regime sequence w/1
        R_O = LE_ON[ES+RS:ES] + 1; // +1 due to K = m-1 w/1
    else if ((LE_O[ES+RS+1] & |(LE_ON[ES-1:0]))) // -ve exponent, regime sequence w/0, last ES bits in LE_ON are not '0
        R_O = LE_ON[ES+RS:ES] + 1'b1; // compensate 1 
    else    //-ve exponent, last ES bits in LE_ON are '0
        R_O = LE_ON[ES+RS:ES];    //  no compensation since 2's comp of 00 is 100, automatically conpensate

  end

  // ------------
  // Rounding
  // ------------

  posit_rounding #(.pFormat(pFormat)) round (.E_O(E_O),.Comp_Mant_N(FMA_Mant_N),.R_O(R_O),.sign_Exponent_O(sign_Exponent_O),.Sign(Sign),.NaR(NaR),.zero(zero),.OUT(result));

  // ------------
  // Stataus
  // ------------
  assign status.NV = 1'b0;
  assign status.DZ = 1'b0;
  assign status.OF = 1'b0;
  assign status.UF = 1'b0;
  assign status.NX = 1'b0;
	
  // -------------------
  // Outputs assignment
  // -------------------

  assign in_ready_o = out_ready_i;
  assign result_o        = result;
  assign status_o        = status;
  assign tag_o           = tag_i;
  assign out_valid_o     = in_valid_i;
  assign busy_o          = in_valid_i;

endmodule
