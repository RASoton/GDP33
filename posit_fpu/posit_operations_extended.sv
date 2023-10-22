
module posit_operations_extended #(
  parameter posit_pkg::posit_format_e   pFormat = posit_pkg::posit_format_e'(0),
  localparam int unsigned WIDTH = posit_pkg::posit_width(pFormat),
  localparam int unsigned ES = posit_pkg::exp_bits(pFormat),
  localparam int unsigned RS = $clog2(WIDTH)
)(
  input logic [WIDTH-1:0] In,
  output logic [WIDTH-1:0] Out
);

  logic sign;
  logic [WIDTH-2:0] remain;
  logic [WIDTH-1:0] mantissa;
  logic [ES-1:0] exponent;
  logic signed [RS:0] regime;  
  logic NaR, zero;

   // Instantiate the posit_extraction module
   posit_extraction #(.N(WIDTH), .ES(ES)) extractor (
        .In(In),
        .Sign(sign),
        .k(regime),
        .Exponent(exponent),
        .Mantissa(mantissa),
        .InRemain(remain),
        .inf(NaR),
        .zero(zero)
   );

  // Function to negate a posit
  function [WIDTH-1:0] negate(input [WIDTH-1:0] posit);
    negate = posit;
    negate[WIDTH-1] = ~posit[WIDTH-1]; // toggle the sign bit
  endfunction

  // Function to return the absolute value of a posit
  function [WIDTH-1:0] abs(input [WIDTH-1:0] posit);
    if (posit[WIDTH-1] == 1) begin // check the sign bit
      abs = negate(posit);
    end else begin
      abs = posit;
    end
  endfunction

  // Function to return the sign of a posit
  function [WIDTH-1:0] get_sign(input [WIDTH-1:0] posit);
    if (posit == {WIDTH{1'b0}}) begin // posit is zero
      get_sign = {WIDTH{1'b0}};
    end else if (posit[WIDTH-1] == 1) begin // posit is negative
      get_sign = {1'b1, 1'b1, {WIDTH-2{1'b0}}}; // -1 in posit
    end else begin // posit is positive
      get_sign = {1'b0, 1'b1, {WIDTH-2{1'b0}}}; // 1 in posit
    end
  endfunction

  // Function to decode posit into decimal value
  function real decode_posit();
    real fraction;
    fraction = compute_fraction(mantissa);
    decode_posit = ((1 - 3*sign) + fraction) * (2**((1 - 2*sign) * (4*regime + exponent + sign)));
  endfunction
  
  // Function to compute fraction 
  function real compute_fraction(input [WIDTH-1:0] mantissa);
    automatic real fraction = 0.0;
    automatic int k = 0;
    for (int i = WIDTH-1; i >= 0; i = i - 1) begin
        fraction = fraction + mantissa[i] * (2**k);
        k = k + 1;
    end
    fraction = fraction / (2**k);
    compute_fraction = fraction;
  endfunction

  // Function to convert regime value to regime bits
  function automatic logic [RS-1:0] regime_to_bits(int v);
    logic [RS-1:0] regime_bits = '0;
    int i;
    if (v >= 0) begin
        for (i = 0; i < v + 1; i = i + 1) begin
            regime_bits[RS - 1 - i] = 1'b1;
        end
        regime_bits[RS - 2 - v] = 1'b0;
    end else begin
        v = -v; 
        for (i = 0; i < v; i = i + 1) begin
            regime_bits[RS - 1 - i] = 1'b0;
        end
        regime_bits[RS - 1 - v] = 1'b1;
    end
    return regime_bits;
  endfunction

  // Function to encode decimal to posit
  function logic [WIDTH-1:0] encode_posit(real value);
    logic sign;
	 logic [WIDTH-1:0] result;
    logic [WIDTH-1:0] fraction;
    logic [ES-1:0] exp;
    logic [RS-1:0] regime;
    int frac_len, regime_len, remaining_len;
    real useed, temp, r, frac;
    
    // Calculate sign and take absolute value
    if (value < 0) begin
        sign = 1'b1;
        value = -value;
    end else begin
        sign = 1'b0;
    end
    
    // Calculate useed
    useed = $pow(2, $pow(2, ES));

    // Determine regime value (temp) and compute r
    if (value > 0 && value < 1) begin
        temp = $floor($log10((1/value)/$log10(useed))) + 1.0;
        temp = -temp;
    end else begin
        temp = $floor($log10(value/$log10(useed)));
    end

    r = $pow(useed, temp);
    
    // Calculate exponent and fraction values
    exp = $floor($log10(value/r)/$log10(2));
    frac = (value/(r*($pow(2.0,exp)))) - 1.0;

    // Convert regime value to bits
    regime = regime_to_bits(temp);

    // Calculate fraction length and fraction bits
    frac_len = WIDTH - ES - 1 - 2;
    fraction = $floor(frac * (2**frac_len));

    if(temp >= 0)
        regime_len = temp + 2;
    else
        regime_len = (temp - 1) * -1;

    // Arrange the combined posit value
    // Sign bit
    result[WIDTH-1] = sign;

    // Regime bits
    for (int i = 0; i < regime_len; i++) begin
        result[WIDTH-2-i] = regime[RS-1-i];
    end

    // Exponent bits
    for (int i = 0; i < ES; i++) begin
        result[WIDTH-2-regime_len-i] = exp[ES-1-i];
    end

    // Fraction bits
    remaining_len = WIDTH - 1 - regime_len - ES;
    for (int i = 0; i < remaining_len; i++) begin
        result[remaining_len-i-1] = fraction[remaining_len-i-1];
    end
    
    return result;
  endfunction

  // Will fix later
  function logic [WIDTH-1:0] nearest_int(logic [WIDTH-1:0] posit);
    real posit_val;
    real rounded_val;
    posit_val = decode_posit();
    rounded_val = $rtoi(posit_val);  
    return encode_posit(rounded_val);
  endfunction

endmodule