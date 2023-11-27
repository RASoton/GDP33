
module posit_sqrt #(
  parameter posit_pkg::posit_format_e   pFormat = posit_pkg::posit_format_e'(0),
	localparam int unsigned N  = posit_pkg::posit_width(pFormat), 
	localparam int unsigned ES = posit_pkg::exp_bits(pFormat), 
	localparam int unsigned RS = $clog2(N)
) (
  input logic Enable,
  input logic signed Sign,
  input logic signed [RS:0] Regime,
  input logic [ES-1:0] Exponent,
  input logic [N-1:0] Mantissa,     
  output logic NaR, 
  output logic [ES-1:0] E_O,
  output logic [RS+4:0] R_O,
  output logic [2*N-1:0] Sqrt_Mant,
  output logic [RS+ES+4:0] Total_EO
);

  logic signed [RS:0] sqrt_r_val;
  logic [N-1:0] sqrt_r;
  logic [N-1:0] r, index, shift, slope, intercept;
  logic [2*N-1:0] sqr_r, mx;
  logic [4*N-1:0] error;
  logic [RS+ES+4:0] Total_EON;

  localparam logic [31:0] slopes_even [0:7]      = '{32'h3a904440, 32'h318b0307, 32'h2a9f9134, 32'h252d7982, 32'h20cd01d7, 32'h1d386f55, 32'h1a3f5400, 32'h17bf1c04};
  localparam logic [31:0] intercepts_even [0:7]  = '{32'hBA904440, 32'hB06A5AE0, 32'hA7C40C98, 32'hA0472C03, 32'h99B67883, 32'h93E50A6F, 32'h8EB11A9C, 32'h8A00B1A2};
  localparam logic [31:0] slopes_odd [0:7]       = '{32'h29692225, 32'h23083E61, 32'h1E23A4A6, 32'h1A49DEF0, 32'h173194AA, 32'h14A9775B, 32'h128F4851, 32'h10CA945A};
  localparam logic [31:0] intercepts_odd [0:7]   = '{32'h81F5CDDF, 32'h7CBE9B83, 32'h76A0DB59, 32'h71556B7F, 32'h6CB0FC16, 32'h6893CC75, 32'h64E5FA23, 32'h619528B5};
  
  always_comb begin
		sqrt_r = 0;
	  sqrt_r_val = 0;
	  index = 0;
	 	slope = 0;
		intercept = 0;
	 	mx = 0;
	 	r = 0;
	 	error = 0;
	 	shift = 0;
	 	NaR = 0;
		R_O = 0;
		E_O = 0;
		Sqrt_Mant = 0;
		Total_EO = 0;
		NaR = 0;
	  if (Enable) begin
      if (Sign == 1'b1)
        NaR = 1'b1; 
    	else begin
        sqrt_r_val = Regime >>> 1;
        E_O = (Regime & 1'b1) ? ((Exponent >> 1) + 2) : (Exponent >> 1);
			  Total_EO = (sqrt_r_val << ES) + E_O;
        if ((Mantissa << 1) == 0) begin
					if (Exponent & 1'b1) 
						Sqrt_Mant = 64'hB504F333F9DE6800; 
					else
						Sqrt_Mant = 64'h8000000000000000;
				end else begin
        	index = (Mantissa >> 28) & 4'h7;
					slope = (Exponent & 1'b1) ? slopes_odd[index] : slopes_even[index];
					intercept = (Exponent & 1'b1) ? intercepts_odd[index] : intercepts_even[index];
					mx = -((slope * Mantissa) >> 31);
        	r = (mx + intercept) << 1;
					for (int i=0; i<3; i++) begin
			    	sqr_r = (r * r) >> 1;
			    	if (Exponent & 1'b1) 
				    	sqr_r = sqr_r << 1;
			   		error = (128'h00000000C00000000000000000000000 - (Mantissa * sqr_r)) >> 64;
			   		r = ((r >> 1) * error) >> 30;
					end
		   		Sqrt_Mant = (Mantissa * (r>>1)) ;
					if (!(Exponent & 1'b1))
						Sqrt_Mant = Sqrt_Mant >> 1;
					Sqrt_Mant = Sqrt_Mant << 2;
				end
     		if(Total_EO[RS+ES+4]) // negative Total_EO
        	Total_EON = -Total_EO;
     		else            // positive exponent
        	Total_EON = Total_EO;
     		if(~Total_EO[RS+ES+4])  //+ve Total_EO
        	R_O = Total_EO[ES+RS+3:ES] + 1; // +1 due to K = m-1 w/1
      	else if (Total_EO[RS+ES+4] & |(Total_EON[ES-1:0]))
        	R_O = Total_EON[ES+RS+3:ES] + 1;
      	else
        	R_O = Total_EON[RS+ES+3:ES];
			end
		end
  end

endmodule