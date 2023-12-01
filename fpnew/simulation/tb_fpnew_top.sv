
module tb_fpnew_top;
  localparam fpnew_pkg::fpu_features_t       Features       = fpnew_pkg::RV32F;
  localparam fpnew_pkg::fpu_implementation_t Implementation = fpnew_pkg::DEFAULT_NOREGS;
  // PulpDivSqrt = 0 enables T-head-based DivSqrt unit. Supported only for FP32-only instances of Fpnew
  localparam logic        PulpDivsqrt    = 1'b1;
  localparam type         TagType        = logic;
  localparam int unsigned TrueSIMDClass  = 0;
  localparam int unsigned EnableSIMDMask = 0;
  localparam int unsigned NumLanes       = fpnew_pkg::max_num_lanes(Features.Width, Features.FpFmtMask, Features.EnableVectors);
  localparam type         MaskType       = logic [NumLanes-1:0];
  localparam int unsigned WIDTH          = Features.Width;
  localparam int unsigned NUM_OPERANDS   = 3;

  logic                               clk_i;
  logic                               rst_ni;
  //  signals
  logic [NUM_OPERANDS-1:0][WIDTH-1:0] operands_i;
  fpnew_pkg::roundmode_e              rnd_mode_i;
  fpnew_pkg::operation_e              op_i;
  logic                               op_mod_i;
  fpnew_pkg::fp_format_e              src_fmt_i;
  fpnew_pkg::fp_format_e              dst_fmt_i;
  fpnew_pkg::int_format_e             int_fmt_i;
  logic                               vectorial_op_i;
  TagType                             tag_i;
  MaskType                            simd_mask_i;
  //  Handshake
  logic                              in_valid_i;
  logic                              in_ready_o;
  logic                              flush_i;
  //  signals
  logic [WIDTH-1:0]                  result_o;
  fpnew_pkg::status_t                status_o;
  TagType                            tag_o;
  //  handshake
  logic                              out_valid_o;
  logic                              out_ready_i;
  // Indication of valid data in flight
  logic                 							busy_o;

	fpnew_top #(.Features(Features)) fpu (.*);

	initial begin
		clk_i = 0;
		forever #5 clk_i = ~clk_i;
	end
	
	initial begin
		rst_ni = 1'b0;
		//operands_i = {32'h0, 32'h0, 32'h0};
		rnd_mode_i = fpnew_pkg::RNE;
		op_i = fpnew_pkg::ADD;
		op_mod_i = 1'b1;
		src_fmt_i = fpnew_pkg::FP32;
		dst_fmt_i = fpnew_pkg::FP32;
		int_fmt_i = fpnew_pkg::INT32;
		vectorial_op_i = 1'b0;
		in_valid_i = 1'b1; // assume data always valid from upstream
		flush_i = 1'b0;

		#10 rst_ni = 1'b1;
		operands_i = {32'h0, 32'h40a947ae, 32'h40000000};
		out_ready_i = 1'b0;

		#5;
		operands_i = {32'h0, 32'h50a947ae, 32'h40040000};
		out_ready_i = 1'b0;

		#5;
		operands_i = {32'h0, 32'h45a947ae, 32'h40005400};
		out_ready_i = 1'b1;

		#5;
		operands_i = {32'h0, 32'h70a947ae, 32'h40002300};
		out_ready_i = 1'b1;

		#500;
		$stop;
	
	end

endmodule             