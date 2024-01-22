// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

// Language: SystemVerilog
// Description: posit format slice creation

module posit_opgroup_fmt_slice #(
  parameter posit_pkg::opgroup_e        OpGroup       = posit_pkg::ADDMUL,
  parameter posit_pkg::posit_format_e   pFormat       = posit_pkg::posit_format_e'(0),
  // FPU configuration
  parameter int unsigned                Width         = 32,
  parameter int unsigned                NumPipeRegs   = 0,
  parameter posit_pkg::pipe_config_t    PipeConfig    = posit_pkg::BEFORE,
  parameter logic                       ExtRegEna     = 1'b0,
  parameter type                        TagType       = logic,
  // Do not change
  localparam int unsigned NUM_OPERANDS   = posit_pkg::num_operands(OpGroup),
  localparam int unsigned ExtRegEnaWidth = NumPipeRegs == 0 ? 1 : NumPipeRegs
) (
  input logic                               clk_i,
  input logic                               rst_ni,
  // Input signals
  input logic [NUM_OPERANDS-1:0][Width-1:0] operands_i,
  input logic [NUM_OPERANDS-1:0]            is_boxed_i,
  input posit_pkg::roundmode_e              rnd_mode_i,
  input posit_pkg::operation_e              op_i,
  input logic                               op_mod_i,
  input TagType                             tag_i,
  // Input Handshake
  input  logic                              in_valid_i,
  output logic                              in_ready_o,
  input  logic                              flush_i,
  // Output signals
  output logic [Width-1:0]                  result_o,
  output posit_pkg::status_t                status_o,
  output logic                              extension_bit_o,
  output TagType                            tag_o,
  // Output handshake
  output logic                              out_valid_o,
  input  logic                              out_ready_i,
  // Indication of valid data in flight
  output logic                              busy_o,
  // External register enable override
  input  logic [ExtRegEnaWidth-1:0]         reg_ena_i
);

  localparam int unsigned POSIT_WIDTH  = posit_pkg::posit_width(pFormat);

  logic [POSIT_WIDTH-1:0] 		 slice_result;
  logic [Width-1:0]            slice_regular_result, slice_class_result;

  posit_pkg::status_t     status;
  logic                   ext_bit = 1'b1; 
  posit_pkg::classmask_e  class_result;
  TagType                 tag; 
  logic                   busy;

  logic result_is_class;

  // -----------
  // Input Side
  // -----------

  logic [POSIT_WIDTH-1:0] local_result; 
  logic                   local_sign;

  logic [NUM_OPERANDS-1:0][POSIT_WIDTH-1:0] local_operands; 
  logic [POSIT_WIDTH-1:0]                   op_result;      
  posit_pkg::status_t                       op_status;


  // Slice out the operands 
  always_comb begin : prepare_input
    for (int i = 0; i < int'(NUM_OPERANDS); i++) begin
      local_operands[i] = operands_i[i][POSIT_WIDTH-1:0];
    end
  end

  // Instantiate the operation from the selected opgroup
  if (OpGroup == posit_pkg::ADDMUL) begin : slice_instance
    posit_fma #(
      .pFormat ( pFormat )
    ) i_fma (
      .clk_i,
      .rst_ni,
      .operands_i      ( local_operands ),
      .op_i,
      .op_mod_i,
      .tag_i,
      .in_valid_i      ( in_valid_i    ),
      .in_ready_o      ( in_ready_o    ),
      .flush_i,
      .result_o        ( op_result     ),
      .status_o        ( op_status     ),
      .tag_o           ( tag           ),
      .out_valid_o     ( out_valid_o   ),
      .out_ready_i     ( out_ready_i   ),
      .busy_o          ( busy          )
    );
    assign result_is_class   = 1'b0;

  end else if (OpGroup == posit_pkg::DIVSQRT) begin : slice_instance
    posit_divsqrt #(
      .pFormat   ( pFormat )
    ) i_divsqrt (
      .clk_i,
      .rst_ni,
      .operands_i      ( local_operands ),
      .rnd_mode_i,
      .op_i,
      .tag_i,
      .in_valid_i      ( in_valid_i     ),
      .in_ready_o      ( in_ready_o     ),
      .flush_i,
      .result_o        ( op_result      ),
      .status_o        ( op_status      ),
      .tag_o           ( tag            ),
      .out_valid_o     ( out_valid_o    ),
      .out_ready_i     ( out_ready_i    ),
      .busy_o          ( busy           )
    );
    assign result_is_class = 1'b0;

  end else if (OpGroup == posit_pkg::NONCOMP) begin : slice_instance
    posit_noncomp #(
      .pFormat   ( pFormat )
    ) i_noncomp (
      .clk_i,
      .rst_ni,
      .operands_i      ( local_operands  ),
      .rnd_mode_i,
      .op_i,
      .op_mod_i,
      .tag_i,
      .in_valid_i      ( in_valid_i      ),
      .in_ready_o      ( in_ready_o      ),
      .flush_i,
      .result_o        ( op_result       ),
      .status_o        ( op_status       ),
      .class_mask_o    ( class_result    ),
      .is_class_o      ( result_is_class ),
      .tag_o           ( tag             ),
      .out_valid_o     ( out_valid_o     ),
      .out_ready_i     ( out_ready_i     ),
      .busy_o          ( busy            )
    );
  end

  // Properly NaN-box or sign-extend the slice result if not in use
  assign local_result  = (out_valid_o | ExtRegEna) ? op_result : '{default: ext_bit};
  assign status   = (out_valid_o | ExtRegEna) ? op_status : '0;

  // Insert lane result into slice result
  assign slice_result[POSIT_WIDTH-1:0] = local_result;

  // ------------
  // Output Side
  // ------------

  assign slice_regular_result = $signed({extension_bit_o, slice_result});

  assign slice_class_result = class_result;

  // Select the proper result
  assign result_o = result_is_class ? slice_class_result : slice_regular_result;

  assign extension_bit_o   = ext_bit; 
  assign tag_o             = tag;    
  assign busy_o            = (| busy);
  assign status_o          = op_status;
  
endmodule
