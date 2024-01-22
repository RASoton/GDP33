// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

// Language: SystemVerilog

/////////////////////////////////////////////////////////////////////
// Design unit: Data Extraction
//            :
// File name  : Posit_Extraction.sv
//            :
// Description: Extracting posit element from N bits  posit input
//            :
// Limitations: 
//            : 
// System     : SystemVerilog IEEE 1800-2005
//            :
// Author     : Xiaoan He (Jasper)
//            : xh2g20@ecs.soton.ac.uk
//
// Revision   : Version 1.2 23/03/2023
/////////////////////////////////////////////////////////////////////

module posit_extraction #
( 
  parameter posit_pkg::posit_format_e   pFormat = posit_pkg::posit_format_e'(0),
  localparam int unsigned N = posit_pkg::posit_width(pFormat), 
  localparam int unsigned ES = posit_pkg::exp_bits(pFormat), 
  localparam int unsigned RS = $clog2(N)
) (
  input  logic signed [N-1:0] In,
  output logic signed Sign,
  output logic signed [RS:0] k,
  output logic [ES-1:0] Exponent,
  output logic [N-1:0] Mantissa,
  output logic signed [N-2:0] InRemain,
  output logic NaR,
  output logic zero
);

  logic zero_check;
  logic RegimeCheck; 
  logic signed [RS:0] EndPosition;
  logic [N-2:0] ShiftedRemain;
  // 8 bits - 1-bit hidden 1, N-ES-2 bit mant from ShiftedRemain, and compensate zeros afterwards
  logic [(N-1)-1-(N-ES-2)-1:0] ZEROs= '0;
  int i;
  posit_LB_detector #(pFormat) LBD1 (.*);

  always_comb begin
    //infinity & zero check;
    zero_check = |In[N-2:0];
    NaR = In[N-1] & (~zero_check);
    zero = ~(In[N-1] | zero_check);

    // Sign Bit Extraction
    Sign = In[N-1];

    // if sign bit is 1, then 2's compliment
    if (Sign)
      InRemain = -In[N-2:0];
    else   
      InRemain = In[N-2:0];


    // Regime Bits Extraction
    /*
     the Leading_Bit_Detector defined before the always_comb block 
     takes the input without sign bit as module input and outputs 
     EndPosition of Regime Bits and RegimeCheck which is the 1st bit of Regime bits
    */
    if(zero)
      k = 0;
    else if (RegimeCheck)
      k = EndPosition - 1'b1;
    else 
      k = -EndPosition;

    //Exponent Bits Extraction
    ShiftedRemain = InRemain << (EndPosition + 1'b1 );
    Exponent = ShiftedRemain[N-2:((N-1)-ES)];

    //Mantissa Bits Extraction
    if (zero)
      Mantissa = {1'b0, ShiftedRemain[N-ES-2:0], ZEROs};
    else
      Mantissa = {1'b1, ShiftedRemain[N-ES-2:0], ZEROs};
  end
endmodule

