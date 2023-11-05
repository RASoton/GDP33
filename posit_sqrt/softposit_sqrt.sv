/*============================================================================

This C source file is part of the SoftFloat IEEE Floating-Point Arithmetic
Package, Release 3d, by John R. Hauser.

Copyright 2011, 2012, 2013, 2014, 2015, 2016 The Regents of the University of
California.  All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

 1. Redistributions of source code must retain the above copyright notice,
    this list of conditions, and the following disclaimer.

 2. Redistributions in binary form must reproduce the above copyright notice,
    this list of conditions, and the following disclaimer in the documentation
    and/or other materials provided with the distribution.

 3. Neither the name of the University nor the names of its contributors may
    be used to endorse or promote products derived from this software without
    specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS "AS IS", AND ANY
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, ARE
DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=============================================================================*/

module softposit_sqrt#(
  parameter N = 32,     
  parameter ES = 2,     
  parameter RS = $clog2(N) 
) (
  input logic [N-1:0] value,              
  output logic signed [N-1:0] result
);

  logic [15:0] approxRecipSqrt0[0:15]; 
  logic [15:0] approxRecipSqrt1[0:15]; 
  logic [3:0] index, exp;
  logic [N-1:0] val, frac, exp_even, r0, mask, exponent, eps;
  logic [2*N-1:0] eSqrR0, sigma0, recipSqrt, sqrSigma0, shiftedFrac, negRem, fraction;
  int shift;

  initial begin
      approxRecipSqrt0 = '{16'hb4c9, 16'hffab, 16'haa7d, 16'hf11c, 16'ha1c5, 16'he4c7, 16'h9a43, 16'hda29, 16'h93b5, 16'hd0e5, 16'h8ded, 16'hc8b7, 16'h88c6, 16'hc16d, 16'h8424, 16'hbae1};
      approxRecipSqrt1 = '{16'ha5a5, 16'hea42, 16'h8c21, 16'hc62d, 16'h788f, 16'haa7f, 16'h6928, 16'h94b6, 16'h5cc7, 16'h8335, 16'h52a6, 16'h74e2, 16'h4a3e, 16'h68fe, 16'h432b, 16'h5efd};
  end
   
  always_comb begin
    val = value;
    if (val & 32'h80000000) begin
        result = 32'h80000000;
    end else if (val == 32'h0) begin
        result = 32'h0;
    end else begin
        if (val & 32'h40000000) begin
            shift = -2;
            while (val & 32'h40000000) begin
                shift = shift + 2;
                val = (val << 1);
            end
        end else begin
            shift = 0;
            while (!(val & 32'h40000000)) begin
                shift = shift - 2;
                val = (val << 1);
            end
        end

        val = val & 32'h3FFFFFFF;
        exponent = (val >> 28);
        shift = shift + (exponent >> 1);;
        exp_even = (1'b1 ^ (exponent & 1'b1));
        val = val & 32'h0FFFFFFF;
        frac = (val | 32'h10000000);
        index = ((frac >> 24) & 4'hE) + exp_even;

        eps = ((frac >> 9) & 16'hFFFF);
        r0 = approxRecipSqrt0[index] - ((approxRecipSqrt1[index] * eps) >> 20);

        eSqrR0 = r0 * r0;
        if (!exp_even)
            eSqrR0 = eSqrR0 << 1;
        sigma0 = 32'hFFFFFFFF & (32'hFFFFFFFF ^ ((eSqrR0 * frac) >> 20));

        recipSqrt = (r0 << 20) + ((r0 * sigma0) >> 21);
        sqrSigma0 = ((sigma0 * sigma0) >> 35);
        recipSqrt = recipSqrt + (((recipSqrt + (recipSqrt >> 2) - (r0 << 19)) * sqrSigma0) >> 46);

        fraction = (frac * recipSqrt) >> 31;
       
        if (exp_even)
            fraction = fraction >> 1;
        exp = shift & 4'b0011;
        if (shift < 0) begin
            shift = (-1 - shift) >> 2;
            val = 32'h20000000 >> shift;
        end else begin
            shift = shift >> 2;
            val = 32'h7FFFFFFF - (32'h3FFFFFFF >> shift);
        end
		
        fraction = fraction + 1'b1;

        if (!(fraction & 4'hF)) begin
            shiftedFrac = fraction >> 1;
            negRem = (shiftedFrac * shiftedFrac) & 32'h1FFFFFFF;
            if (negRem & 32'h100000000) 
                fraction = fraction | 1;
            else if (negRem)
                fraction = fraction - 1;
        end
	
        fraction = fraction & 32'hFFFFFFFF;
	
        mask = 1 << (4 + shift);
        if (mask & frac) begin
            if (((mask-1) & fraction) || ((mask << 1) & fraction)) begin
                fraction = fraction + (mask << 1);
            end
        end

        result = val | (exp << (27-shift)) | (fraction >> (5+shift));
    end
  end
endmodule

