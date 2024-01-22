// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

// Language: SystemVerilog
// Description: posit-based package

package posit_pkg;

  // ---------
  // POSIT TYPES
  // ---------
  // | Enumerator | Format           | Width  | REGIME   | EXP_BITS | FRAC_BITS
  // |:----------:|------------------|-------:|:--------:|:--------:|:--------:
  // | POSIT32    | POSIT binary32   | 32 bit | 2 to 31  |  0 to 2  | 0 to 27
 
  // Encoding for a format
  typedef struct packed {
    int unsigned width;
    int unsigned exp_bits;
  } posit_encoding_t;

  localparam int unsigned NUM_POSIT_FORMATS = 1; // change me to add formats
  localparam int unsigned POSIT_FORMAT_BITS = $clog2(NUM_POSIT_FORMATS);

  // POSIT formats
  typedef enum logic [POSIT_FORMAT_BITS-1:0] {
    POSIT32    = 'd0
    // add new formats here
  } posit_format_e;

  // Encodings for supported posit formats
  localparam posit_encoding_t [0:NUM_POSIT_FORMATS-1] POSIT_ENCODINGS  = '{
    '{32,  2} // POSIT 32-bit with 2-bit exponent
    // add new formats here
  };

  typedef logic [0:NUM_POSIT_FORMATS-1]       fmt_logic_t;    // Logic indexed by FP format (for masks)
  typedef logic [0:NUM_POSIT_FORMATS-1][31:0] fmt_unsigned_t; // Unsigned indexed by FP format

  // ---------
  // INT TYPES
  // ---------
  // | Enumerator | Width  |
  // |:----------:|-------:|
  // | INT8       |  8 bit |
  // | INT16      | 16 bit |
  // | INT32      | 32 bit |
  // | INT64      | 64 bit |
  // *NOTE:* Add new formats only at the end of the enumeration for backwards compatibilty!
  
  localparam int unsigned NUM_INT_FORMATS = 4; // change me to add formats
  localparam int unsigned INT_FORMAT_BITS = $clog2(NUM_INT_FORMATS);

  // Int formats
  typedef enum logic [INT_FORMAT_BITS-1:0] {
    INT8,
    INT16,
    INT32,
    INT64
    // add new formats here
  } int_format_e;

  // Returns the width of an INT format by index
  function automatic int unsigned int_width(int_format_e ifmt);
    unique case (ifmt)
      INT8:  return 8;
      INT16: return 16;
      INT32: return 32;
      INT64: return 64;
      default: begin
        // pragma translate_off
        $fatal(1, "Invalid INT format supplied");
        // pragma translate_on
        // just return any integer to avoid any latches
        // hopefully this error is caught by simulation
        return INT8;
      end
    endcase
  endfunction

  typedef logic [0:NUM_INT_FORMATS-1] ifmt_logic_t; // Logic indexed by INT format (for masks)

  // --------------
  // POSIT OPERATIONS
  // --------------

  localparam int unsigned NUM_OPGROUPS = 3;

  // Each POSIT operation belongs to an operation group
  typedef enum logic [1:0] {
    ADDMUL, DIVSQRT, NONCOMP /*,CONV */
  } opgroup_e;


  typedef enum logic  [1:0] {
    SGN      = 2'b00,
    SGNJN     = 2'b01,
    SGNJX     = 2'b10
  } sgnj_e;// SIGN injection

  typedef enum logic [1:0] {
    MIN    = 2'b00,
    MAX    = 2'b01
  } minmax_e;// MIN MAX

  typedef enum logic [1:0] {
    LE    = 2'b00,
    LT    = 2'b01,
    EQ    = 2'b10
  } cmp_e;

  localparam int unsigned OP_BITS = 4;

  typedef enum logic [OP_BITS-1:0] {
    FMADD, FNMSUB, ADD, MUL,     // ADDMUL operation group
    DIV, SQRT,                   // DIVSQRT operation group
    SGNJ, MINMAX, CMP, CLASSIFY // NONCOMP operation group
    //F2F, F2I, I2F, CPKAB, CPKCD  // CONV operation group
  } operation_e;

  // -------------------
  // RISC-V POSIT-SPECIFIC
  // -------------------
  // Rounding modes 
  typedef enum logic [2:0] {
    RNE = 3'b000,
    RTZ = 3'b001,
    RDN = 3'b010,
    RUP = 3'b011,
    RMM = 3'b100,
    ROD = 3'b101, 
    DYN = 3'b111
  } roundmode_e;

  // Status flags
  typedef struct packed {
    logic NV; // Invalid
    logic DZ; // Divide by zero
    logic OF; // Overflow
    logic UF; // Underflow
    logic NX; // Inexact
  } status_t;

  // Information about a floating point value
  typedef struct packed {
    logic is_zero;       // is the value zero
    logic is_NaR;        // is the value NaR
    logic is_pos;
    logic is_neg;
  } posit_info_t;

  // Classification mask
  typedef enum logic [3:0] {
    ZERO    = 4'b0001,
    NAR     = 4'b0010,
    POS     = 4'b0100,
    NEG     = 4'b1000
  } classmask_e;

  typedef enum logic [31:0] {
    POSIT_NAR = 32'h8000_0000,
    POSIT_ZERO = 32'b0
  } posit_special_values_e;

  // ------------------
  // POSIT configuration
  // ------------------
  // Pipelining registers can be inserted (at elaboration time) into operational units
  typedef enum logic [1:0] {
    BEFORE,     // registers are inserted at the inputs of the unit
    AFTER,      // registers are inserted at the outputs of the unit
    INSIDE,     // registers are inserted at predetermined (suboptimal) locations in the unit
    DISTRIBUTED // registers are evenly distributed, INSIDE >= AFTER >= BEFORE
  } pipe_config_t;

  // Arithmetic units can be arranged in parallel (per format), merged (multi-format) or not at all.
  typedef enum logic [1:0] {
    DISABLED, // arithmetic units are not generated
    PARALLEL, // arithmetic units are generated in prallel slices, one for each format
    MERGED    // arithmetic units are contained within a merged unit holding multiple formats
  } unit_type_t;

  // Array of unit types indexed by format
  typedef unit_type_t [0:NUM_POSIT_FORMATS-1] fmt_unit_types_t;

  // Array of format-specific unit types by opgroup
  typedef fmt_unit_types_t [0:NUM_OPGROUPS-1] opgrp_fmt_unit_types_t;
  // same with unsigned
  typedef fmt_unsigned_t [0:NUM_OPGROUPS-1] opgrp_fmt_unsigned_t;

  // POSIT configuration: features
  typedef struct packed {
    int unsigned Width;
    logic        EnableVectors;
    logic        EnableNanBox;
    fmt_logic_t  PositFmtMask;
    ifmt_logic_t IntFmtMask;
  } posit_features_t;

  localparam posit_features_t POSIT32_CONFIG = '{
    Width:         32,
    EnableVectors: 1'b0,
    EnableNanBox:  1'b1,
    PositFmtMask:  5'b00001,
    IntFmtMask:    4'b0000
  };

  // POSIT configuraion: implementation
  typedef struct packed {
    opgrp_fmt_unsigned_t   PipeRegs;
    opgrp_fmt_unit_types_t UnitTypes;
    pipe_config_t          PipeConfig;
  } posit_implementation_t;

  localparam posit_implementation_t DEFAULT_NOREGS = '{
    PipeRegs:   '{default: 0},
    UnitTypes:  '{'{default: PARALLEL},   // ADDMUL
                  '{default: PARALLEL},   // DIVSQRT
                  '{default: PARALLEL}   // NONCOMP
                  /*'{default: PARALLEL}*/},  // CONV
    PipeConfig: BEFORE
  };


  // -----------------------
  // Synthesis optimization
  // -----------------------
  localparam logic DONT_CARE = 1'b1; // the value to assign as don't care

  // -------------------------
  // General helper functions
  // -------------------------
  function automatic int minimum(int a, int b);
    return (a < b) ? a : b;
  endfunction

  function automatic int maximum(int a, int b);
    return (a > b) ? a : b;
  endfunction

  // -------------------------------------------
  // Helper functions for POSIT formats and values
  // -------------------------------------------
  // Returns the width of a POSIT format
  function automatic int unsigned posit_width(posit_format_e fmt);
    return POSIT_ENCODINGS[fmt].width;
  endfunction

  // Returns the number of exponent bits for a format
  function automatic int unsigned exp_bits(posit_format_e fmt);
    return POSIT_ENCODINGS[fmt].exp_bits;
  endfunction

  // Returns the widest POSIT format present
  function automatic int unsigned max_posit_width(fmt_logic_t cfg);
    automatic int unsigned res = 0;
    for (int unsigned i = 0; i < NUM_POSIT_FORMATS; i++)
      if (cfg[i])
        res = unsigned'(maximum(res, posit_width(posit_format_e'(i))));
    return res;
  endfunction

  // Returns the narrowest POSIT format present
  function automatic int unsigned min_posit_width(fmt_logic_t cfg);
    automatic int unsigned res = max_posit_width(cfg);
    for (int unsigned i = 0; i < NUM_POSIT_FORMATS; i++)
      if (cfg[i])
        res = unsigned'(minimum(res, posit_width(posit_format_e'(i))));
    return res;
  endfunction

  // --------------------------------------------------
  // Helper functions for operations and POSIT structure
  // --------------------------------------------------
  // Returns the operation group of the given operation
  function automatic opgroup_e get_opgroup(operation_e op);
    unique case (op)
      FMADD, FNMSUB, ADD, MUL:     return ADDMUL;
      DIV, SQRT:                   return DIVSQRT;
      SGNJ, MINMAX, CMP, CLASSIFY:  return NONCOMP;
      //F2F, F2I, I2F, CPKAB, CPKCD: return CONV;
      default:                     return NONCOMP;
    endcase
  endfunction

  // Returns the number of operands by operation group
  function automatic int unsigned num_operands(opgroup_e grp);
    unique case (grp)
      ADDMUL:  return 3;
      DIVSQRT: return 2;
      NONCOMP: return 2;
      //CONV:    return 2; 
      default: return 0;
    endcase
  endfunction

endpackage
