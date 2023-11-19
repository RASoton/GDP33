
package posit_pkg;

  // ---------
  // POSIT TYPES
  // ---------
  // | Enumerator | Format           | Width  | REGIME | EXP_BITS | FRAC_BITS
  // |:----------:|------------------|-------:|:------:|:--------:|:--------:
  // | POSIT32    | POSIT binary32   | 32 bit | r      | 2        | 29-r
  
  // Max array size for allocation
  typedef struct packed {
    int unsigned total_bits;
	 int unsigned max_regime_bits;
	 int unsigned exp_bits;
    int unsigned max_frac_bits;
  } posit_size_t;


  localparam int unsigned NUM_POSIT_FORMATS = 1; // change me to add formats
  localparam int unsigned POSIT_FORMAT_BITS = $clog2(NUM_POSIT_FORMATS);

  // POSIT formats
  typedef enum logic [POSIT_FORMAT_BITS-1:0] {
    POSIT32    = 'd0
    // add new formats here
  } posit_format_e;

  // Encodings for supported POSIT formats
  localparam posit_size_t [0:NUM_POSIT_FORMATS-1] POSIT_SIZES  = '{
    '{32, 5, 2, 27} // total bits, max_regime_bits, exp_bits, max_frac_bits
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

  localparam int unsigned NUM_OPGROUPS = 4;

  // Each POSIT operation belongs to an operation group
  typedef enum logic [1:0] {
    ADDMUL, DIVSQRT, NONCOMP, CONV
  } opgroup_e;

  localparam int unsigned OP_BITS = 4;

  typedef enum logic [OP_BITS-1:0] {
    FMADD, FNMSUB, ADD, MUL,     // ADDMUL operation group
    DIV, SQRT,                   // DIVSQRT operation group
    SGN, MINMAX, CMP, CLASSIFY, // NONCOMP operation group
    F2F, F2I, I2F, CPKAB, CPKCD  // CONV operation group
  } operation_e;

  // -------------------
  // RISC-V POSIT-SPECIFIC
  // -------------------
  // Rounding modes (need change)
  typedef enum logic [2:0] {
    RNE = 3'b000,
    RTZ = 3'b001,
    RDN = 3'b010,
    RUP = 3'b011,
    RMM = 3'b100,
    ROD = 3'b101,  // This mode is not defined in RISC-V POSIT-SPEC
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
    logic        EnableNaRBox;
    fmt_logic_t  PositFmtMask;
    ifmt_logic_t IntFmtMask;
  } posit_features_t;

  localparam posit_features_t POSIT32_CONFIG = '{
    Width:         32,
    EnableVectors: 1'b0,
    EnableNaRBox:  1'b0,
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
    UnitTypes:  '{'{default: PARALLEL}, // ADDMUL
                  '{default: MERGED},   // DIVSQRT
                  '{default: PARALLEL}, // NONCOMP
                  '{default: MERGED}},  // CONV
    PipeConfig: BEFORE
  };

  localparam posit_implementation_t DEFAULT_SNITCH = '{
    PipeRegs:   '{default: 1},
    UnitTypes:  '{'{default: PARALLEL}, // ADDMUL
                  '{default: DISABLED}, // DIVSQRT
                  '{default: PARALLEL}, // NONCOMP
                  '{default: MERGED}},  // CONV
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
    return POSIT_SIZES[fmt].total_bits;
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

  // Returns the maximum number of regime bits for a format
  function automatic int unsigned max_regime_bits(posit_format_e fmt);
    return POSIT_SIZES[fmt].max_regime_bits;
  endfunction

  // Returns the number of exponent bits for a format
  function automatic int unsigned exp_bits(posit_format_e fmt);
    return POSIT_SIZES[fmt].exp_bits;
  endfunction

  // Returns the maximum number of fraction bits for a format
  function automatic int unsigned max_frac_bits(posit_format_e fmt);
    return POSIT_SIZES[fmt].max_frac_bits;
  endfunction
 
  // -------------------------------------------
  // Helper functions for INT formats and values
  // -------------------------------------------
  // Returns the widest INT format present
  function automatic int unsigned max_int_width(ifmt_logic_t cfg);
    automatic int unsigned res = 0;
    for (int ifmt = 0; ifmt < NUM_INT_FORMATS; ifmt++) begin
      if (cfg[ifmt]) res = maximum(res, int_width(int_format_e'(ifmt)));
    end
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
      SGN, MINMAX, CMP, CLASSIFY: return NONCOMP;
      F2F, F2I, I2F, CPKAB, CPKCD: return CONV;
      default:                     return NONCOMP;
    endcase
  endfunction

  // Returns the number of operands by operation group
  function automatic int unsigned num_operands(opgroup_e grp);
    unique case (grp)
      ADDMUL:  return 3;
      DIVSQRT: return 2;
      NONCOMP: return 2;
      CONV:    return 3; // vectorial casts use 3 operands
      default: return 0;
    endcase
  endfunction

  typedef enum logic  [1:0] {
    SGNJ    = 2'b00,
    NAR     = 2'b01,
    POS     = 2'b10,
  } signinject_e;// SIGN injection

  typedef enum logic [1:0] {
    RNE    = 2'b00,
    RTZ    = 2'b01,
  } minmax_e;// MIN MAX

endpackage
