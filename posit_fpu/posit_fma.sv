module posit_fma #(
    parameter posit_pkg::posit_format_e   pFormat = posit_pkg::posit_format_e'(0),
	localparam int unsigned N = posit_pkg::posit_width(pFormat), 
	localparam int unsigned ES = posit_pkg::exp_bits(pFormat), 
	localparam int unsigned RS = $clog2(N)
 )
(
    input logic clk_i,
    input logic rst_ni,

    // Input signal
    input logic [2:0][N-1:0]        operands_i, // 3 operands
    // input  posit_pkg::roundmode_e   rnd_mode_i,
    input posit_pkg::operation_e    op_i,
    input logic                     op_mod_i,
    // input logic                     tag_i,

    // Input handshake
    input  logic                    in_valid_i,
    output logic                    in_ready_o,
    input  logic                    flush_i,

    // Output signal
    output logic [WIDTH-1:0]        result_o,
    output posit_pkg::status_t      status_o,
    output logic                    tag_o,

    // Output handshake
    input  logic                    out_valid_i,
    output logic                    out_valid_o,

    // Indication of valid data in flight
    output logic                    busy_o
);

assign  in_ready_o = out_ready_i ;
logic   MultAdd_valid; 
assign  MultAdd_valid   = in_valid_i & (op_i == (posit_pkg::FMADD|posit_pkg::FNMSUB|posit_pkg::ADD|posit_pkg::MUL )) & in_ready_o & ~flush_i;

posit_result_t input_a = extractor.extract(operands_i[0]); 
posit_result_t input_b = extractor.extract(operands_i[1]); 
posit_result_t input_c = extractor.extract(operands_i[2]); 

logic op_N, op_sub;
// arithmetic output
logic exponent_output;
logic regime_output;
logic output_sign;
logic [2N-1:0]output_frac;
logic inf_flag, zero_flag;
logic regime_sign;
logic sign_Exponent_O;

// Fused Multiply Add
Arithmetic_FMA Compute (
.op_N(op_N), .op_sub(op_sub),
.Sign1(input_a.sign), .Sign2(input_b.sign), .Sign3(input_c.sign),
.k1(input_a.regime), .k2(input_b.regime), .k3(input_c.regime),
.Exponent1(input_a.exponent), .Exponent2(input_b.exponent), .Exponent3(input_c.exponent),
.Mantissa1(input_a.fraction), .Mantissa2(input_b.fraction), .Mantissa3(input_c.fraction),
.inf1(input_a.NaR), .inf2(input_b.NaR), .inf3(input_c.NaR),
.zero1(input_a.zero), .zero2(input_b.zero), .zero3(input_c.zero),
.FMA_Mant_N(output_frac),
.sign_Exponent_O(sign_Exponent_O),
.E_O(exponent_output),
.R_O(regime_output),
.inf(inf_flag), .zero(zero_flag), .Sign(output_sign))

// RNE
Rounding rounding (
.E_O(exponent_output),
.Comp_Mant_N(output_frac),
.R_O(regime_output), 
.sign_Exponent_O(sign_Exponent_O),
.Sign(output_sign),
.inf(inf_flag), .zero(zero_flag),
.OUT(result_o)
)

always_comb : operation_select
begin
    
if(op_mod_i) // if sub-mode
    input_c.sign = ~input_c.sign; // reverse sign of input_c
else
    input_c.sign = input_c.sign;

unique case (op_i)
    posit_pkg::FMADD: 
    begin
        op_N = 0;
        op_sub = 0;
    end; 
    posit_pkg::FNMSUB: 
    begin
        op_N = 1;
        op_sub = 1;
    end
    posit_pkg::ADD:
    begin
        input_a = '{sign:1'b0, regime:2'b10, expoent:'0, fraction:'0}; // inputA=1 => basic add
    end
    posit_pkg::MUL:
    begin
        input_c = '{sign:1'b0, regime:2'b00, exponent:'0, fraction:'0};// inputC=1 => basic mult
    end
default:
    begin
        input_a  = '{default: posit_pkg::DONT_CARE};
        input_b  = '{default: posit_pkg::DONT_CARE};
        input_c  = '{default: posit_pkg::DONT_CARE};   
    end
endcase
end
endmodule