
module posit_sqrt #(
  parameter N = 32,     
  parameter ES = 2,     
  parameter RS = $clog2(N) 
) (
  input logic signed sign,
  input logic signed [RS:0] regime,
  input logic [ES-1:0] exponent,
  input logic [N-1:0] fraction,     
  output logic [N-1:0] result
);

  logic signed [RS:0] sqrt_r_val;
  logic [N-1:0] sqrt_r, sqrt_e, sqrt_f;
  logic [N-1:0] r0, index, shift;
  logic [2*N-1:0] sqr_r0, sqr_r1, r1, r2;
  logic [4*N-1:0] error, temp;

  localparam [31:0] approxRecipSqrtOdd [0:7]= '{32'hb4c9a5a5, 32'haa7d8c21, 32'ha1c5788f, 32'h9a436928, 32'h93b55cc7, 32'h8ded52a6, 32'h88c64a3e, 32'h8424432b};
  localparam [31:0] approxRecipSqrtEven [0:7]  = '{32'hffabea42, 32'hf11cc62d, 32'he4c7aa7f, 32'hda2994b6, 32'hd0e58335, 32'hc8b774e2, 32'hc16d68fe, 32'hbae15efd};
  
  always_comb begin
    if (sign == 1'b1)
        result = 32'h80000000; //return NaR
    else if (sign == 0 && regime == 0 && exponent == 0 && fraction == 0)
        result = 32'b0;  //return 0
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
			r0 = (exponent & 1'b1) ? approxRecipSqrtOdd[index] : approxRecipSqrtEven[index];
			sqr_r0 = (r0 * r0) >> 1;
			if (exponent & 1'b1) 
				sqr_r0 = sqr_r0 << 1;
			error = (128'h00000000C00000000000000000000000 - (fraction * sqr_r0)) >> 64;
			r1 = ((r0 >> 1) * error) >> 30;

			sqr_r1 = (r1 * r1) >> 1;
			if (exponent & 1'b1) 
				sqr_r1 = sqr_r1 << 1;
			error = (128'h00000000C00000000000000000000000 - (fraction * sqr_r1)) >> 64;
			r2 = ((r1 >> 1) * error) >> 31;

		    temp = (fraction * r2) >> 29;
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
