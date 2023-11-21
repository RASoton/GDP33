
`include "registers.svh"

module posit_divsqrt #(
  parameter posit_pkg::fmt_logic_t   positFmtConfig  = '1,
  // positU configuration
  parameter int unsigned             NumPipeRegs = 0,
  parameter posit_pkg::pipe_config_t PipeConfig  = posit_pkg::AFTER,
  parameter type                     TagType     = logic,
  parameter type                     AuxType     = logic,
  // Do not change
  localparam int unsigned WIDTH       = posit_pkg::max_posit_width(positFmtConfig),
  localparam int unsigned NUM_FORMATS = 1,
  localparam int unsigned ExtRegEnaWidth = NumPipeRegs == 0 ? 1 : NumPipeRegs
) (
  input  logic                        clk_i,
  input  logic                        rst_ni,
  // Input signals
  input  logic [1:0][WIDTH-1:0]       operands_i, // 2 operands
  input  logic [NUM_FORMATS-1:0][1:0] is_boxed_i, // 2 operands
  input  posit_pkg::roundmode_e       rnd_mode_i,
  input  posit_pkg::operation_e       op_i,
  input  posit_pkg::posit_format_e    dst_fmt_i,
  input  TagType                      tag_i,
  input  logic                        mask_i,
  input  AuxType                      aux_i,
  input  logic                        vectorial_op_i,
  // Input Handshake
  input  logic                        in_valid_i,
  output logic                        in_ready_o,
  output logic                        divsqrt_done_o,
  input  logic                        simd_synch_done_i,
  output logic                        divsqrt_ready_o,
  input  logic                        simd_synch_rdy_i,
  input  logic                        flush_i,
  // Output signals
  output logic [WIDTH-1:0]            result_o,
  output posit_pkg::status_t          status_o,
  output logic                        extension_bit_o,
  output TagType                      tag_o,
  output logic                        mask_o,
  output AuxType                      aux_o,
  // Output handshake
  output logic                        out_valid_o,
  input  logic                        out_ready_i,
  // Indication of valid data in flight
  output logic                        busy_o,
  // External register enable override
  input  logic [ExtRegEnaWidth-1:0]   reg_ena_i
);

  // ----------
  // Constants
  // ----------
  // Pipelines
  localparam NUM_INP_REGS = (PipeConfig == posit_pkg::BEFORE)
                            ? NumPipeRegs
                            : (PipeConfig == posit_pkg::DISTRIBUTED
                               ? (NumPipeRegs / 2) // Last to get distributed regs
                               : 0); // no regs here otherwise
  localparam NUM_OUT_REGS = (PipeConfig == posit_pkg::AFTER || PipeConfig == posit_pkg::INSIDE)
                            ? NumPipeRegs
                            : (PipeConfig == posit_pkg::DISTRIBUTED
                               ? ((NumPipeRegs + 1) / 2) // First to get distributed regs
                               : 0); // no regs here otherwise

  // ---------------
  // Input pipeline
  // ---------------
  // Selected pipeline output signals as non-arrays
  logic [1:0][WIDTH-1:0] operands_q;
  posit_pkg::roundmode_e rnd_mode_q;
  posit_pkg::operation_e op_q;
  posit_pkg::posit_format_e dst_fmt_q;
  logic                  in_valid_q;

  // Input pipeline signals, index i holds signal after i register stages
  logic                  [0:NUM_INP_REGS][1:0][WIDTH-1:0]       inp_pipe_operands_q;
  posit_pkg::roundmode_e [0:NUM_INP_REGS]                       inp_pipe_rnd_mode_q;
  posit_pkg::operation_e [0:NUM_INP_REGS]                       inp_pipe_op_q;
  posit_pkg::posit_format_e [0:NUM_INP_REGS]                    inp_pipe_dst_fmt_q;
  TagType                [0:NUM_INP_REGS]                       inp_pipe_tag_q;
  logic                  [0:NUM_INP_REGS]                       inp_pipe_mask_q;
  AuxType                [0:NUM_INP_REGS]                       inp_pipe_aux_q;
  logic                  [0:NUM_INP_REGS]                       inp_pipe_vec_op_q;
  logic                  [0:NUM_INP_REGS]                       inp_pipe_valid_q;
  // Ready signal is combinatorial for all stages
  logic [0:NUM_INP_REGS] inp_pipe_ready;

  // Input stage: First element of pipeline is taken from inputs
  assign inp_pipe_operands_q[0] = operands_i;
  assign inp_pipe_rnd_mode_q[0] = rnd_mode_i;
  assign inp_pipe_op_q[0]       = op_i;
  assign inp_pipe_dst_fmt_q[0]  = dst_fmt_i;
  assign inp_pipe_tag_q[0]      = tag_i;
  assign inp_pipe_mask_q[0]     = mask_i;
  assign inp_pipe_aux_q[0]      = aux_i;
  assign inp_pipe_vec_op_q[0]   = vectorial_op_i;
  assign inp_pipe_valid_q[0]    = in_valid_i;
  // Input stage: Propagate pipeline ready signal to upstream circuitry
  assign in_ready_o = inp_pipe_ready[0];
  // Generate the register stages
  for (genvar i = 0; i < NUM_INP_REGS; i++) begin : gen_input_pipeline
    // Internal register enable for this stage
    logic reg_ena;
    // Determine the ready signal of the current stage - advance the pipeline:
    // 1. if the next stage is ready for our data
    // 2. if the next stage only holds a bubble (not valid) -> we can pop it
    assign inp_pipe_ready[i] = inp_pipe_ready[i+1] | ~inp_pipe_valid_q[i+1];
    // Valid: enabled by ready signal, synchronous clear with the flush signal
    `FFLARNC(inp_pipe_valid_q[i+1], inp_pipe_valid_q[i], inp_pipe_ready[i], flush_i, 1'b0, clk_i, rst_ni)
    // Enable register if pipleine ready and a valid data item is present
    assign reg_ena = (inp_pipe_ready[i] & inp_pipe_valid_q[i]) | reg_ena_i[i];
    // Generate the pipeline registers within the stages, use enable-registers
    `FFL(inp_pipe_operands_q[i+1], inp_pipe_operands_q[i], reg_ena, '0)
    `FFL(inp_pipe_rnd_mode_q[i+1], inp_pipe_rnd_mode_q[i], reg_ena, posit_pkg::RNE)
    `FFL(inp_pipe_op_q[i+1],       inp_pipe_op_q[i],       reg_ena, posit_pkg::FMADD)
    `FFL(inp_pipe_dst_fmt_q[i+1],  inp_pipe_dst_fmt_q[i],  reg_ena, posit_pkg::posit_format_e'(0))
    `FFL(inp_pipe_tag_q[i+1],      inp_pipe_tag_q[i],      reg_ena, TagType'('0))
    `FFL(inp_pipe_mask_q[i+1],     inp_pipe_mask_q[i],     reg_ena, '0)
    `FFL(inp_pipe_aux_q[i+1],      inp_pipe_aux_q[i],      reg_ena, AuxType'('0))
    `FFL(inp_pipe_vec_op_q[i+1],   inp_pipe_vec_op_q[i],   reg_ena, AuxType'('0))
  end
  // Output stage: assign selected pipe outputs to signals for later use
  assign operands_q = inp_pipe_operands_q[NUM_INP_REGS];
  assign rnd_mode_q = inp_pipe_rnd_mode_q[NUM_INP_REGS];
  assign op_q       = inp_pipe_op_q[NUM_INP_REGS];
  assign dst_fmt_q  = inp_pipe_dst_fmt_q[NUM_INP_REGS];
  assign in_valid_q = inp_pipe_valid_q[NUM_INP_REGS];

  // -----------------
  // Input processing
  // -----------------
  logic [1:0]       divsqrt_fmt;
  logic [1:0][WIDTH-1:0] divsqrt_operands; // those are fixed to 32bit

  // Translate posit formats into divsqrt formats
  always_comb begin : translate_fmt
    unique case (dst_fmt_q)
      posit_pkg::POSIT32:    divsqrt_fmt = 2'b00;
 
      default:            divsqrt_fmt = 2'b00; // maps also posit8 to posit16
    endcase

  	divsqrt_operands[0] = operands_q[0];
  	divsqrt_operands[1] = operands_q[1];

  end



  // ------------
  // Control FSM
  // ------------

  logic in_ready;               // input handshake with upstream
  logic div_valid, sqrt_valid;  // input signalling with unit
  logic unit_ready, unit_done, unit_done_q;  // status signals from unit instance
  logic op_starting;            // high in the cycle a new operation starts
  logic out_valid, out_ready;   // output handshake with downstream
  logic unit_busy;              // valid data in flight
  logic simd_synch_done;
  // FSM states
  typedef enum logic [1:0] {IDLE, BUSY, HOLD} fsm_state_e;
  fsm_state_e state_q, state_d;

  // Valids are gated by the FSM ready. Invalid input ops run a sqrt to not lose illegal instr.
  assign div_valid   = in_valid_q & (op_q == posit_pkg::DIV) & in_ready & ~flush_i;
  assign sqrt_valid  = in_valid_q & (op_q != posit_pkg::DIV) & in_ready & ~flush_i;
  assign op_starting = div_valid | sqrt_valid;

  // Hold additional information while the operation is in progress
  TagType result_tag_q;
  logic result_mask_q;
  AuxType result_aux_q;
  logic result_vec_op_q;

  // Fill the registers everytime a valid operation arrives (load FF, active low asynch rst)
  `FFL(result_tag_q,    inp_pipe_tag_q[NUM_INP_REGS], op_starting, '0)
  `FFL(result_mask_q,   inp_pipe_mask_q[NUM_INP_REGS],op_starting, '0)
  `FFL(result_aux_q,    inp_pipe_aux_q[NUM_INP_REGS], op_starting, '0)
  `FFL(result_vec_op_q, inp_pipe_vec_op_q[NUM_INP_REGS], op_starting, '0)

  // Wait for other lanes only if the operation is vectorial
  assign simd_synch_done = simd_synch_done_i || ~result_vec_op_q;

  // Valid synch with other lanes
  // When one divsqrt unit completes an operation, keep its done high, waiting for the other lanes
  // As soon as all the lanes are over, we can clear this FF and start with a new operation
  `FFLARNC(unit_done_q, unit_done, unit_done, simd_synch_done, 1'b0, clk_i, rst_ni)
  // Tell the other units that this unit has finished now or in the past
  assign divsqrt_done_o = (unit_done_q | unit_done) & result_vec_op_q;

  // Ready synch with other lanes
  // Bring the FSM-generated ready outside the unit, to synchronize it with the other lanes
  assign divsqrt_ready_o = in_ready;
  // Upstream ready comes from sanitization FSM, and it is synched among all the lanes
  assign inp_pipe_ready[NUM_INP_REGS] = result_vec_op_q ? simd_synch_rdy_i : in_ready;

  // FSM to safely apply and receive data from DIVSQRT unit
  always_comb begin : flag_fsm
    // Default assignments
    in_ready     = 1'b0;
    out_valid    = 1'b0;
    unit_busy    = 1'b0;
    state_d      = state_q;

    unique case (state_q)
      // Waiting for work
      IDLE: begin
        in_ready = 1'b1; // we're ready
        if (in_valid_q && unit_ready) begin // New work arrives
          state_d = BUSY; // go into processing state
        end
      end
      // Operation in progress
      BUSY: begin
        unit_busy = 1'b1; // data in flight
        // If all the lanes are done with processing
        if (simd_synch_done_i || (~result_vec_op_q && unit_done)) begin
          out_valid = 1'b1; // try to commit result downstream
          // If downstream accepts our result
          if (out_ready) begin
            state_d = IDLE; // we anticipate going back to idling..
            in_ready = 1'b1; // we acknowledge the instruction
            if (in_valid_q && unit_ready) begin // ..unless new work comes in
              state_d  = BUSY; // and stay busy with it
            end
          // Otherwise if downstream is not ready for the result
          end else begin
            state_d     = HOLD; // wait for the pipeline to take the data
          end
        end
      end
      // Waiting with valid result for downstream
      HOLD: begin
        unit_busy    = 1'b1; // data in flight
        out_valid    = 1'b1; // try to commit result downstream
        // If the result is accepted by downstream
        if (out_ready) begin
          state_d = IDLE; // go back to idle..
          if (in_valid_q && unit_ready) begin // ..unless new work comes in
            in_ready = 1'b1; // acknowledge the new transaction
            state_d  = BUSY; // will be busy with the next instruction
          end
        end
      end
      // fall into idle state otherwise
      default: state_d = IDLE;
    endcase

    // Flushing overrides the other actions
    if (flush_i) begin
      unit_busy = 1'b0; // data is invalidated
      out_valid = 1'b0; // cancel any valid data
      state_d   = IDLE; // go to default state
    end
  end

  // FSM status register (asynch active low reset)
  `FF(state_q, state_d, IDLE)

  // -----------------
  // DIVSQRT instance
  // -----------------
  logic [WIDTH-1:0]   unit_result;
  logic [WIDTH-1:0]   adjusted_result, held_result_q;
  posit_pkg::status_t unit_status, held_status_q;
  logic               hold_en;

  posit_divsqrt_wrapper i_divsqrt (
   .Clk_CI           ( clk_i               ),
   .Rst_RBI          ( rst_ni              ),
   .Div_start_SI     ( div_valid           ),
   .Sqrt_start_SI    ( sqrt_valid          ),
   .Operand_a_DI     ( divsqrt_operands[0] ),
   .Operand_b_DI     ( divsqrt_operands[1] ),
   .RM_SI            ( rnd_mode_q          ),
   .Format_sel_SI    ( divsqrt_fmt         ),
   .Kill_SI          ( flush_i             ),
   .Result_DO        ( unit_result         ),
   .Fflags_SO        ( unit_status         ),
   .Ready_SO         ( unit_ready          ),
   .Done_SO          ( unit_done           )
  );

  // Adjust result width and fix posit8
  assign adjusted_result = unit_result;

  // Hold the result when one lane has finished execution, except when all the lanes finish together,
  // or the operation is not vectorial, and the result can be accepted downstream
  assign hold_en = unit_done & (~simd_synch_done_i | ~out_ready) & ~(~result_vec_op_q & out_ready);
  // The Hold register (load, no reset)
  `FFLNR(held_result_q, adjusted_result, hold_en, clk_i)
  `FFLNR(held_status_q, unit_status,     hold_en, clk_i)

  // --------------
  // Output Select
  // --------------
  logic [WIDTH-1:0]   result_d;
  posit_pkg::status_t status_d;
  // Prioritize hold register data
  assign result_d = unit_done_q ? held_result_q : adjusted_result;
  assign status_d = unit_done_q ? held_status_q : unit_status;

  // ----------------
  // Output Pipeline
  // ----------------
  // Output pipeline signals, index i holds signal after i register stages
  logic               [0:NUM_OUT_REGS][WIDTH-1:0] out_pipe_result_q;
  posit_pkg::status_t [0:NUM_OUT_REGS]            out_pipe_status_q;
  TagType             [0:NUM_OUT_REGS]            out_pipe_tag_q;
  logic               [0:NUM_OUT_REGS]            out_pipe_mask_q;
  AuxType             [0:NUM_OUT_REGS]            out_pipe_aux_q;
  logic               [0:NUM_OUT_REGS]            out_pipe_valid_q;
  // Ready signal is combinatorial for all stages
  logic [0:NUM_OUT_REGS] out_pipe_ready;

  // Input stage: First element of pipeline is taken from inputs
  assign out_pipe_result_q[0] = result_d;
  assign out_pipe_status_q[0] = status_d;
  assign out_pipe_tag_q[0]    = result_tag_q;
  assign out_pipe_mask_q[0]   = result_mask_q;
  assign out_pipe_aux_q[0]    = result_aux_q;
  assign out_pipe_valid_q[0]  = out_valid;
  // Input stage: Propagate pipeline ready signal to inside pipe
  assign out_ready = out_pipe_ready[0];
  // Generate the register stages
  for (genvar i = 0; i < NUM_OUT_REGS; i++) begin : gen_output_pipeline
    // Internal register enable for this stage
    logic reg_ena;
    // Determine the ready signal of the current stage - advance the pipeline:
    // 1. if the next stage is ready for our data
    // 2. if the next stage only holds a bubble (not valid) -> we can pop it
    assign out_pipe_ready[i] = out_pipe_ready[i+1] | ~out_pipe_valid_q[i+1];
    // Valid: enabled by ready signal, synchronous clear with the flush signal
    `FFLARNC(out_pipe_valid_q[i+1], out_pipe_valid_q[i], out_pipe_ready[i], flush_i, 1'b0, clk_i, rst_ni)
    // Enable register if pipleine ready and a valid data item is present
    assign reg_ena = (out_pipe_ready[i] & out_pipe_valid_q[i]) | reg_ena_i[NUM_INP_REGS + i];
    // Generate the pipeline registers within the stages, use enable-registers
    `FFL(out_pipe_result_q[i+1], out_pipe_result_q[i], reg_ena, '0)
    `FFL(out_pipe_status_q[i+1], out_pipe_status_q[i], reg_ena, '0)
    `FFL(out_pipe_tag_q[i+1],    out_pipe_tag_q[i],    reg_ena, TagType'('0))
    `FFL(out_pipe_mask_q[i+1],   out_pipe_mask_q[i],   reg_ena, '0)
    `FFL(out_pipe_aux_q[i+1],    out_pipe_aux_q[i],    reg_ena, AuxType'('0))
  end
  // Output stage: Ready travels backwards from output side, driven by downstream circuitry
  assign out_pipe_ready[NUM_OUT_REGS] = out_ready_i;
  // Output stage: assign module outputs
  assign result_o        = out_pipe_result_q[NUM_OUT_REGS];
  assign status_o        = out_pipe_status_q[NUM_OUT_REGS];
  assign extension_bit_o = 1'b1; // always NaN-Box result
  assign tag_o           = out_pipe_tag_q[NUM_OUT_REGS];
  assign mask_o          = out_pipe_mask_q[NUM_OUT_REGS];
  assign aux_o           = out_pipe_aux_q[NUM_OUT_REGS];
  assign out_valid_o     = out_pipe_valid_q[NUM_OUT_REGS];
  assign busy_o          = (| {inp_pipe_valid_q, unit_busy, out_pipe_valid_q});

endmodule