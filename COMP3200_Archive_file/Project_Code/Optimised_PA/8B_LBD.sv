/////////////////////////////////////////////////////////////////////
// Design unit: Leading Bit Detector
//            :
// File name  : 8B_LBD.sv
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
// Revision   : Version 1.1 21/2/2023
/////////////////////////////////////////////////////////////////////

module Leading_Bit_Detector_8B #( parameter N = 32, parameter ES = 2, parameter RS = $clog2(N))
(
    input  logic  [N-1:0] In,
    output logic signed [RS:0] EndPosition
);

logic Check; 
int i;
logic signed [RS:0] EP;

always_comb
begin
    Check = 1; 
    
    EndPosition = '0;
    // EndPosition = EndPosition + 1'b1; // initial EP starts from InRemain[1] as InRemain[0] is RC

    for(i = 1; i < N; i++) 
        begin
            /* 
            compareing MSB of InRemain to the follwing bits
            until the different bit turns up    
            */
            if (Check != In[(N-i)])
                //begin
                EndPosition = EndPosition + 1'b1;
                //end
            else 
                break;
        end
end
endmodule