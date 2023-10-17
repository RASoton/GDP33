package posit_pkg;

  // ---------
  // POSIT TYPES
  // ---------
  // | Enumerator | Format           | Width  | REGIME | EXP_BITS | MAN_BITS
  // |:----------:|------------------|-------:|:------:|:--------:|:--------:
  // | POSIT32    | POSIT binary32   | 32 bit | r      | 2        | 29-r

typedef enum logic [OP_BITS-1:0] {
  FMADD, FNMSUB, ADD, MUL,     
  DIV, SQRT,                   
  SGNJ, MINMAX, CMP, CLASSIFY, 
  F2F, F2I, I2F, CPKAB, CPKCD  
} operation_e;

typedef struct packed {
  logic NV; // Invalid
  logic DZ; // Divide by zero
  logic OF; // Overflow
  logic UF; // Underflow
  logic NX; // Inexact
} status_t;

typedef enum logic [2:0] {
  RNE = 3'b000,
  RTZ = 3'b001,
  RDN = 3'b010,
  RUP = 3'b011,
  RMM = 3'b100,
  ROD = 3'b101,  // This mode is not defined in RISC-V FP-SPEC
  DYN = 3'b111
} roundmode_e;

