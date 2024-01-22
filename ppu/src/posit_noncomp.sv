// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

// Language: SystemVerilog
// Description: posit-based non-computational operations

module posit_noncomp #(
  parameter posit_pkg::posit_format_e   pFormat = posit_pkg::posit_format_e'(0),
  localparam int unsigned WIDTH = posit_pkg::posit_width(pFormat)
) (
  input logic                      clk_i,
  input logic                      rst_ni,
  // Input signals
  input logic [1:0][WIDTH-1:0]     operands_i, // 2 operands
  input posit_pkg::roundmode_e     rnd_mode_i,
  input posit_pkg::operation_e     op_i,
  input logic 					           op_mod_i,
  input logic			                 tag_i,
  // Input Handshake
  input  logic                     in_valid_i,
  output logic                     in_ready_o,
  input  logic                     flush_i,
  // Output signals
  output logic [WIDTH-1:0]         result_o,
  output posit_pkg::status_t       status_o,
  output posit_pkg::classmask_e    class_mask_o,
  output logic                     is_class_o,
  output logic                     tag_o,
  // Output handshake
  output logic                     out_valid_o,
  input  logic                     out_ready_i,
  // Indication of valid data in flight
  output logic                     busy_o
);

  // ---------------------
  // Input classification
  // ---------------------
  posit_pkg::posit_info_t [1:0] info;

  // Classify input
  posit_classifier #(
   .pFormat     ( pFormat ),
   .NumOperands ( 2       )
  ) i_class_a (
   .operands_i ( operands_i ),
   .info_o     ( info       )
  );

  logic signed [WIDTH-1:0] operand_a, operand_b; //can treat as 2's complement
  logic operand_a_sign, operand_b_sign;
  posit_pkg::posit_info_t info_a, info_b;

  assign operand_a      = operands_i[0];
  assign operand_b      = operands_i[1];
  assign operand_a_sign = operand_a[WIDTH-1];
  assign operand_b_sign = operand_b[WIDTH-1];
  assign info_a         = info[0];
  assign info_b         = info[1];

  logic is_NaR;

  // Reduction for special case handling
  assign is_NaR  = info_a.is_NaR || info_b.is_NaR;

  logic operands_equal, operand_a_smaller;

  // Equality checks for zeroes too
  assign operands_equal = (operand_a == operand_b);
  // Invert result if non-zero signs involved 
  assign operand_a_smaller = (operand_a < operand_b);

  // ---------------
  // Sign Injection
  // ---------------
  logic [WIDTH-1:0]   sgnj_result;
  posit_pkg::status_t sgnj_status;

  // Sign Injection - operation is encoded in rnd_mode_i
  // RNE = SGNJ, RTZ = SGNJN, RDN = SGNJX, RUP = Passthrough (no NaN-box check)
  always_comb begin : sign_injections
    logic sign_a, sign_b; // internal signs
    logic flip_sign; // if posit should be flipped to perform injection
    // Default assignment
    sgnj_result = operand_a; // result based on operand a

    sign_a = operand_a_sign;
    sign_b = operand_b_sign;

    // Do the sign injection based on rm field
    unique case (rnd_mode_i)
      posit_pkg::SGN  : flip_sign = sign_a ^ sign_b;  // SGNJ
      posit_pkg::SGNJN: flip_sign = sign_a ^ ~sign_b; // SGNJN
      posit_pkg::SGNJX: flip_sign = sign_b;           // SGNJX
      posit_pkg::RUP  : flip_sign = 0;                // passthrough
      default: sgnj_result = '{default: posit_pkg::DONT_CARE}; // don't care
    endcase
    
    sgnj_result = (flip_sign)? -operand_a : operand_a;

  end

  assign sgnj_status = '0;        // sign injections never raise exceptions

  // ------------------
  // Minimum / Maximum
  // ------------------
  logic [WIDTH-1:0]   minmax_result;
  posit_pkg::status_t minmax_status;

  // Minimum/Maximum - operation is encoded in rnd_mode_i
  // RNE = MIN, RTZ = MAX
  always_comb begin : min_max
    // All posit values can be used
    minmax_status = '0;
    // Both NaR inputs cause a NaR output
    if (info_a.is_NaR && info_b.is_NaR)
      minmax_result = posit_pkg::POSIT_NAR; // only for 32-bit
    // If one operand is NaR, the non-NaR operand is returned
    else if (info_a.is_NaR) minmax_result = operand_b;
    else if (info_b.is_NaR) minmax_result = operand_a;
    // Otherwise decide according to the operation
    else begin
      unique case (rnd_mode_i)
        posit_pkg::MIN: minmax_result = operand_a_smaller ? operand_a : operand_b; // MIN
        posit_pkg::MAX: minmax_result = operand_a_smaller ? operand_b : operand_a; // MAX
      default: minmax_result = '{default: posit_pkg::DONT_CARE}; // don't care
      endcase
    end
  end

  // ------------
  // Comparisons
  // ------------
  logic [WIDTH-1:0]   cmp_result;
  posit_pkg::status_t cmp_status;
  logic               cmp_extension_bit;

  // Comparisons - operation is encoded in rnd_mode_i
  // RNE = LE, RTZ = LT, RDN = EQ
  // op_mod_i inverts boolean outputs
  always_comb begin : comparisons
    // Default assignment
  	cmp_result = '0; // false
    cmp_status = '0; // no invalid values for posits

    unique case (rnd_mode_i)
      posit_pkg::LE: begin // Less than or equal
        cmp_result = (operand_a_smaller | operands_equal) ^ op_mod_i;
      end
      posit_pkg::LT: begin // Less than
        cmp_result = (operand_a_smaller & ~operands_equal) ^ op_mod_i;
      end
      posit_pkg::EQ: begin // Equal
        cmp_result = operands_equal ^ op_mod_i;
      end
      default: cmp_result = '{default: posit_pkg::DONT_CARE}; // don't care
    endcase
  end

  // ---------------
  // Classification
  // ---------------
  posit_pkg::status_t    class_status;
  logic                  class_extension_bit;
  posit_pkg::classmask_e class_mask_d; // the result is actually here

  // Classification - always return the classification mask on the dedicated port
  always_comb begin : classify
    if (info_a.is_NaR)
      class_mask_d = posit_pkg::NAR;
    else if (info_a.is_zero)
      class_mask_d = posit_pkg::ZERO;
    else if (info_a.is_neg)
      class_mask_d = posit_pkg::NEG;
    else
      class_mask_d = posit_pkg::POS;
  end

  assign class_status        = '0;   // classification does not set flags

  // -----------------
  // Result selection
  // -----------------
  logic [WIDTH-1:0]      result_d;
  posit_pkg::status_t    status_d;
  logic                  is_class_d;

  // Select result
  always_comb begin : select_result
    unique case (op_i)
      posit_pkg::SGNJ: begin
      result_d        = sgnj_result;
      status_d        = sgnj_status;
      end
      posit_pkg::MINMAX: begin
      result_d        = minmax_result;
      status_d        = minmax_status;
      end
      posit_pkg::CMP: begin
      result_d        = cmp_result;
      status_d        = cmp_status;
      end
      posit_pkg::CLASSIFY: begin
      result_d        = '{default: posit_pkg::DONT_CARE}; // unused
      status_d        = class_status;
      end
      default: begin
      result_d        = '{default: posit_pkg::DONT_CARE}; // dont care
      status_d        = '{default: posit_pkg::DONT_CARE}; // dont care
      end
    endcase
  end

  assign is_class_d = (op_i == posit_pkg::CLASSIFY);

  // Output stage: assign module outputs
  assign result_o        = result_d;
  assign status_o        = status_d;
  assign class_mask_o    = class_mask_d;
  assign is_class_o      = is_class_d;
  assign tag_o           = tag_i;
  assign out_valid_o     = in_valid_i;
  assign busy_o          = in_valid_i;
  assign in_ready_o      = out_ready_i;
endmodule
