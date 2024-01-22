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
// Design unit: Leading Bit Detector
//            :
// File name  : Leading_Bit_Detector.sv
//            :
// Description: Given a bit find the first bit different from it
//            :
// Limitations: 
//            : 
// System     : SystemVerilog IEEE 1800-2005
//            :
// Author     : Xiaoan He (Jasper)
//            : xh2g20@ecs.soton.ac.uk
//
// Revision   : Version 1.1 24/03/2023
/////////////////////////////////////////////////////////////////////

module posit_LB_detector #( 
  parameter posit_pkg::posit_format_e   pFormat = posit_pkg::posit_format_e'(0),
  localparam int unsigned N = posit_pkg::posit_width(pFormat), 
  localparam int unsigned ES = posit_pkg::exp_bits(pFormat), 
  localparam int unsigned RS = $clog2(N)
) (
  input  logic signed [N-2:0] InRemain,
  output logic signed [RS:0] EndPosition,
  output logic RegimeCheck
);

  //logic RegimeCheck; 
  int i;
  logic signed [RS:0] EP;
  
  always_comb begin
    RegimeCheck = InRemain[N-2]; //the MSB of InRemain (In[6])is the number to be checked
    
    EP = '0;
    EndPosition = EP + 1'b1; // initial EP starts from InRemain[1] as InRemain[0] is RC

    for(i = 1; i < (N-1); i++) begin
      /* 
      compareing MSB of InRemain to the follwing bits
      until the different bit turns up    
      */
      if (RegimeCheck == InRemain[((N-2)-i)])
        EndPosition = EndPosition + 1'b1;
      else 
        break;
      end
  end
endmodule