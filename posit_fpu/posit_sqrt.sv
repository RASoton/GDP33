
module posit_sqrt #(
  parameter N = 32,     
  parameter ES = 2,     
  parameter RS = $clog2(N) 
) (
  input logic signed sign,
  input logic signed [RS:0] regime,
  input logic [ES-1:0] exponent,
  input logic [N-1:0] fraction,     
  input logic zero,
  output logic [N-1:0] result
);

  logic signed [RS:0] sqrt_r_val;
  logic [N-1:0] sqrt_r, sqrt_e, sqrt_f;
  logic [N-1:0] r, index, shift, slope, intercept;
  logic [2*N-1:0] sqr_r, mx;
  logic [4*N-1:0] error, temp;

  localparam [31:0] slopes_even [0:7]      = '{32'h3a904440, 32'h318b0307, 32'h2a9f9134, 32'h252d7982, 32'h20cd01d7, 32'h1d386f55, 32'h1a3f5400, 32'h17bf1c04};
  localparam [31:0] intercepts_even [0:7]  = '{32'hBA904440, 32'hB06A5AE0, 32'hA7C40C98, 32'hA0472C03, 32'h99B67883, 32'h93E50A6F, 32'h8EB11A9C, 32'h8A00B1A2};
  localparam [31:0] slopes_odd [0:7]       = '{32'h29692225, 32'h23083E61, 32'h1E23A4A6, 32'h1A49DEF0, 32'h173194AA, 32'h14A9775B, 32'h128F4851, 32'h10CA945A};
  localparam [31:0] intercepts_odd [0:7]   = '{32'h81F5CDDF, 32'h7CBE9B83, 32'h76A0DB59, 32'h71556B7F, 32'h6CB0FC16, 32'h6893CC75, 32'h64E5FA23, 32'h619528B5};
  
  always_comb begin
    if (sign == 1'b1)
        result = 32'h80000000; //return NaR if input is NaR
    else if (zero)
        result = 32'b0;  //return 0 if input is NaR
    else begin
        sqrt_r_val = regime >>> 1;
        sqrt_e = (regime & 1'b1) ? ((exponent >> 1) + 2) : (exponent >> 1);
        if ((fraction << 1) == 0) begin
			if (exponent & 1'b1) 
				sqrt_f = 32'h6A09E667; 
			else
				sqrt_f = 32'b0;
		end else begin
        	index = (fraction >> 28) & 4'h7;
			slope = (exponent & 1'b1) ? slopes_odd[index] : slopes_even[index];
			intercept = (exponent & 1'b1) ? intercepts_odd[index] : intercepts_even[index];
			mx = -((slope * fraction) >> 31);
        	r = (mx + intercept) << 1;
			for (int i=0; i<3; i++) begin
			    sqr_r = (r * r) >> 1;
			    if (exponent & 1'b1) 
				    sqr_r = sqr_r << 1;
			    error = (128'h00000000C00000000000000000000000 - (fraction * sqr_r)) >> 64;
			    r = ((r >> 1) * error) >> 30;
			end
		    temp = (fraction * (r>>1)) >> 29;
		    sqrt_f = temp[31:0];
			if (!(exponent & 1'b1))
				sqrt_f = sqrt_f >> 1;
		end
		if (sqrt_r_val < 0) begin
			shift = -(sqrt_r_val-1) + 3;
			sqrt_r = 32'h80000000 >> -(sqrt_r_val-1); //including sign
		end else begin
			shift = sqrt_r_val + 5;
			sqrt_r = 32'h7FFFFFFF - (32'h3FFFFFFF >> sqrt_r_val); //including sign
		end
		result = sqrt_r | (sqrt_e << (32-shift)) | (sqrt_f >> shift);
    end
  end
endmodule
