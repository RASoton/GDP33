// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

// Language: SystemVerilog
// Description: posit operation groups creation

module posit_opgroup_block #(
  parameter posit_pkg::opgroup_e        OpGroup       = posit_pkg::ADDMUL,
  // FPU configuration
  parameter int unsigned                Width         = 32,
  parameter posit_pkg::fmt_logic_t      PositFmtMask  = '1,
  parameter posit_pkg::ifmt_logic_t     IntFmtMask    = '1,
  parameter posit_pkg::fmt_unsigned_t   FmtPipeRegs   = '{default: 0},
  parameter posit_pkg::fmt_unit_types_t FmtUnitTypes  = '{default: posit_pkg::PARALLEL},
  parameter posit_pkg::pipe_config_t    PipeConfig    = posit_pkg::BEFORE,
  parameter type                        TagType       = logic,
  // Do not change
  localparam int unsigned NUM_FORMATS  = posit_pkg::NUM_POSIT_FORMATS,
  localparam int unsigned NUM_OPERANDS = posit_pkg::num_operands(OpGroup)
) (
  input logic                                     clk_i,
  input logic                                     rst_ni,
  // Input signals
  input logic [NUM_OPERANDS-1:0][Width-1:0]       operands_i,
  input logic [NUM_FORMATS-1:0][NUM_OPERANDS-1:0] is_boxed_i,
  input posit_pkg::roundmode_e                    rnd_mode_i,
  input posit_pkg::operation_e                    op_i,
  input logic                                     op_mod_i,
  input posit_pkg::posit_format_e                 src_fmt_i,
  input posit_pkg::posit_format_e                 dst_fmt_i,
  input posit_pkg::int_format_e                   int_fmt_i,
  input TagType                                   tag_i,
  // Input Handshake
  input  logic                                    in_valid_i,
  output logic                                    in_ready_o,
  input  logic                                    flush_i,
  // Output signals
  output logic [Width-1:0]                        result_o,
  output posit_pkg::status_t                      status_o,
  output logic                                    extension_bit_o,
  output TagType                                  tag_o,
  // Output handshake
  output logic                                    out_valid_o,
  input  logic                                    out_ready_i,
  // Indication of valid data in flight
  output logic                                    busy_o
);

  // ----------------
  // Type Definition
  // ----------------
  typedef struct packed {
    logic [Width-1:0]   result;
    posit_pkg::status_t status;
    logic               ext_bit;
    TagType             tag;
  } output_t;

  // Handshake signals for the slices
  logic [NUM_FORMATS-1:0] fmt_in_ready, fmt_out_valid, fmt_out_ready, fmt_busy;
  output_t [NUM_FORMATS-1:0] fmt_outputs;

  // -----------
  // Input Side
  // -----------
  assign in_ready_o = in_valid_i & fmt_in_ready[dst_fmt_i]; // Ready is given by selected format

  // -------------------------
  // Generate Parallel Slices
  // -------------------------
  for (genvar fmt = 0; fmt < int'(NUM_FORMATS); fmt++) begin : gen_parallel_slices

    // Generate slice only if format enabled
    if (PositFmtMask[fmt] && (FmtUnitTypes[fmt] == posit_pkg::PARALLEL)) begin : active_format

      logic in_valid;

      assign in_valid = in_valid_i & (dst_fmt_i == fmt); // enable selected format

      posit_opgroup_fmt_slice #(
        .OpGroup       ( OpGroup                      ),
        .pFormat       ( posit_pkg::posit_format_e'(fmt) ),
        .Width         ( Width                        ),
        .NumPipeRegs   ( FmtPipeRegs[fmt]             ),
        .PipeConfig    ( PipeConfig                   ),
        .TagType       ( TagType                      )
      ) i_fmt_slice (
        .clk_i,
        .rst_ni,
        .operands_i     ( operands_i               ),
        .is_boxed_i     ( is_boxed_i[fmt]          ),
        .rnd_mode_i,
        .op_i,
        .op_mod_i,
        .tag_i,
        .in_valid_i     ( in_valid                 ),
        .in_ready_o     ( fmt_in_ready[fmt]        ),
        .flush_i,
        .result_o       ( fmt_outputs[fmt].result  ),
        .status_o       ( fmt_outputs[fmt].status  ),
        .extension_bit_o( fmt_outputs[fmt].ext_bit ),
        .tag_o          ( fmt_outputs[fmt].tag     ),
        .out_valid_o    ( fmt_out_valid[fmt]       ),
        .out_ready_i    ( fmt_out_ready[fmt]       ),
        .busy_o         ( fmt_busy[fmt]            ),
        .reg_ena_i      ( '0                       )
      );
    end
  end


  // ------------------
  // Arbitrate Outputs
  // ------------------
  output_t arbiter_output;

  // Round-Robin arbiter to decide which result to use
  rr_arb_tree #(
    .NumIn     ( NUM_FORMATS ),
    .DataType  ( output_t    ),
    .AxiVldRdy ( 1'b1        )
  ) i_arbiter (
    .clk_i,
    .rst_ni,
    .flush_i,
    .rr_i   ( '0             ),
    .req_i  ( fmt_out_valid  ),
    .gnt_o  ( fmt_out_ready  ),
    .data_i ( fmt_outputs    ),
    .gnt_i  ( out_ready_i    ),
    .req_o  ( out_valid_o    ),
    .data_o ( arbiter_output ),
    .idx_o  ( /* unused */   )
  );

  // Unpack output
  assign result_o        = arbiter_output.result;
  assign status_o        = arbiter_output.status;
  assign extension_bit_o = arbiter_output.ext_bit;
  assign tag_o           = arbiter_output.tag;

  assign busy_o = (| fmt_busy);

endmodule
