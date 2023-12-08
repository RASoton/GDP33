// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

// Wrapper for a fpnew
// Contributor: Davide Schiavone <davide@openhwgroup.org>

module cv32e40p_fp_wrapper
  import cv32e40p_apu_core_pkg::*;
(
    // Clock and Reset
    input logic clk_i,
    input logic rst_ni,

    // APU Side: Master port
    input  logic apu_req_i,
    output logic apu_gnt_o,

    // request channel
    input logic [   APU_NARGS_CPU-1:0][31:0] apu_operands_i,
    input logic [     APU_WOP_CPU-1:0]       apu_op_i,
    input logic [APU_NDSFLAGS_CPU-1:0]       apu_flags_i,

    // response channel
    output logic                        apu_rvalid_o,
    output logic [                31:0] apu_rdata_o,
    output logic [APU_NUSFLAGS_CPU-1:0] apu_rflags_o
);


  import cv32e40p_pkg::*;
  import fpnew_pkg::*;

  logic [        fpnew_pkg::OP_BITS-1:0] fpu_op;
  logic                                  fpu_op_mod;
  logic                                  fpu_vec_op;

  logic [ fpnew_pkg::FP_FORMAT_BITS-1:0] fpu_dst_fmt;
  logic [ fpnew_pkg::FP_FORMAT_BITS-1:0] fpu_src_fmt;
  logic [fpnew_pkg::INT_FORMAT_BITS-1:0] fpu_int_fmt;
  logic [                      C_RM-1:0] fp_rnd_mode;



  // assign apu_rID_o = '0;
  assign {fpu_vec_op, fpu_op_mod, fpu_op}                     = apu_op_i;

  assign {fpu_int_fmt, fpu_src_fmt, fpu_dst_fmt, fp_rnd_mode} = apu_flags_i;

  //---------------
  // PPU instance
  //---------------
  
  posit_top i_ppu_bulk // use default parameters
  (
      .clk_i         (clk_i),
      .rst_ni        (rst_ni),
      .operands_i    (apu_operands_i),
      .rnd_mode_i    (posit_pkg::roundmode_e'(fp_rnd_mode)),
      .op_i          (posit_pkg::operation_e'(fpu_op)),
      .op_mod_i      (fpu_op_mod),
      .src_fmt_i     (posit_pkg::posit_format_e'(fpu_src_fmt)),
      .dst_fmt_i     (posit_pkg::posit_format_e'(fpu_dst_fmt)),
      .int_fmt_i     (posit_pkg::int_format_e'(fpu_int_fmt)),
      .vectorial_op_i(fpu_vec_op),
      .tag_i         (1'b0),
      .in_valid_i    (apu_req_i),
      .in_ready_o    (apu_gnt_o),
      .flush_i       (1'b0),
      .result_o      (apu_rdata_o),
      .status_o      (apu_rflags_o),
      .tag_o         (/* unused */ ),
      .out_valid_o   (apu_rvalid_o),
      .out_ready_i   (1'b1),
      .busy_o        (/* unused */ )
  );
  

endmodule  // cv32e40p_fp_wrapper

