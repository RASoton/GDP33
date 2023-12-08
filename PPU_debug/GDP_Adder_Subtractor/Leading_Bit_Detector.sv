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

module Leading_Bit_Detector #( parameter N = 32, parameter ES = 2, parameter RS = $clog2(N))
(
    input  logic signed [N-2:0] InRemain,
    output logic signed [RS:0] EndPosition,
    output logic RegimeCheck
);

//logic RegimeCheck; 
int i;
logic signed [RS:0] EP;

always_comb
begin
    RegimeCheck = InRemain[N-2]; //the MSB of InRemain (In[6])is the number to be checked
    
    EP = '0;
    EndPosition = EP + 1'b1; // initial EP starts from InRemain[1] as InRemain[0] is RC

    for(i = 1; i < (N-1); i++) 
        begin
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