/////////////////////////////////////////////////////////////////////
// Design unit: Add/Subtract Arithmetic
//            :
// File name  : Arithmetic_Add_Sub.sv
//            :
// Description: Mantissa addition and subtraction
//            : exponent and regime computation
//            :
// Limitations: 
//            : 
// System     : SystemVerilog IEEE 1800-2005
//            :
// Author     : Xiaoan He (Jasper)
//            : xh2g20@soton.ac.uk
//
// Revision   : Version 1.3 23/03/2023
/////////////////////////////////////////////////////////////////////

module Add_Subtract #(parameter N = 32, parameter ES = 2, parameter RS = $clog2(N)) 
(
    input  logic signed Sign1, Sign2,
    input  logic signed [RS:0] k1,k2,
    input  logic [ES-1:0] Exponent1, Exponent2,
    input  logic [N-1:0] Mantissa1, Mantissa2,
    input  logic signed [N-2:0] InRemain1, InRemain2,
    input  logic inf1, inf2,
    input  logic zero1, zero2,
    output logic [N:0] Add_Mant,
    output logic [N-1:0] Add_Mant_N,
    output logic signed [ES+RS:0] LE_O,
    output logic [ES-1:0] E_O,
    output logic signed [RS:0] R_O,
    output logic LS
);
logic inf, zero;
logic Operation;

// components to corresponding logic, L - Large S - Small
logic signed [N-2:0] LIn, SIn;
logic SS;
logic [RS:0] LR, SR;
logic LRC, SRC;
logic [ES-1:0]LE, SE;
logic [N-1:0]LM, SM, SM_tmp;

logic [N-1:0] E_diff;
logic [N-1:0] Add_Mant_sft;
logic [N-1:0] LBD_in;
logic Greater_Than;
logic signed [RS:0] R_diff;
logic Mant_Ovf;
logic signed [RS:0] shift;
logic [ES+RS:0] LE_ON;

Leading_Bit_Detector_8B #(.N(N), .ES(ES)) LBD_8B (.In(LBD_in), .EndPosition(shift));

always_comb
begin
    // check infinity and zero
    inf = inf1 | inf2;
	zero = zero1 & zero2;


    //////      ADDITION ARITHMETIC     //////

    // Confirm the operation (s1 XNOR s2)
    Operation = Sign1 ~^ Sign2 ;

    // Find the greater InRemain
    Greater_Than = (InRemain1[N-2:0] >  InRemain2[N-2:0])? 1'b1 : 1'b0;

    // Assign components to corresponding logic, L - Large S - Small
    LIn = Greater_Than ? InRemain1 : InRemain2;
    LS = Greater_Than ? Sign1 : Sign2;
    LR = Greater_Than ? k1 : k2;
    LRC = Greater_Than? InRemain1[N-2] : InRemain2[N-2];
    LE = Greater_Than ? Exponent1 : Exponent2;
    LM = Greater_Than ? Mantissa1 : Mantissa2; // the first bit (0) is reserved for overflow detection
    
    SIn = Greater_Than ? InRemain2 : InRemain1;
    SS = Greater_Than ? Sign2 : Sign1;
    SR = Greater_Than ? k2 : k1;
    SRC = Greater_Than? InRemain2[N-2] : InRemain1[N-2];
    SE = Greater_Than ? Exponent2 : Exponent1;
    SM = Greater_Than ? Mantissa2 : Mantissa1;


    //// Mantissa Addition ////
    // find the regime difference
    R_diff = LR - SR;

    /*
    after the R_diff found, remember that the regime contributes into the exponent
    as (Useed ^ k) where Useed = 2^(2^ES) 
    so the E_diff is (R_diff x log2(useed) + LE - SE)
    the reason why it is R_diff x log2(useed) is
    the exponent (2 ^ what)is what we want to find
    for exponent bits, it is the difference
    for regime bits, they are log2(Useed ^ k) which is k x (2^ES)
    */

    E_diff = (R_diff*(2**(ES))) + (LE - SE); 

    SM_tmp = SM >> E_diff;
    if (Operation)
        Add_Mant = LM + SM_tmp;
    else
        Add_Mant = LM - SM_tmp;
    
    // check for Mantissa Overflow
    Mant_Ovf = Add_Mant[N];

    /*
     In the case of subtraction between two close numbers
     MSBs may lost, it is useful to detect the 
     Leading ONE and left shift accordingly
    */
    
    // (MSB OR 2nd MSB) bit since LBD_IN is for leading bit
    LBD_in = {(Add_Mant[N] | Add_Mant[N-1]), Add_Mant[N-2:0]}; 
    // --------------------CHECK------------------------------------
    // Add_Mant_sft = Add_Mant[N:1] << shift; // FIXME
    // if(Add_Mant_sft[N-1])
    //     Add_Mant_N = Add_Mant_sft[N-1:0];
    // else
    //     Add_Mant_N = {Add_Mant_sft[N-2:0],1'b0};

        if(Mant_Ovf)
        begin
            Add_Mant_sft = Add_Mant[N:1] << shift;
        end
        else
        begin
            Add_Mant_sft = Add_Mant[N-1:0] << shift;           
        end
        Add_Mant_N = Add_Mant_sft;
    // -----------------------------------CHECK END-----------------------------

    // Compute regime and exponent of final result
    
    /* 
    The exponent is mainly based on the larger input
    also taking overflow and left shift into account
    */
    LE_O = {LR, LE} + Mant_Ovf - shift; 
    if (LE_O[RS+ES])
        LE_ON = -LE_O;
    else
        LE_ON = LE_O;

    if (LE_O[ES+RS] & |(LE_ON[ES-1:0]))
        E_O = -LE_ON[ES-1:0];
    else
        E_O = LE_ON[ES-1:0];

    if (~LE_O[ES+RS] || (LE_O[ES+RS] & |(LE_ON[ES-1:0])))
        R_O = LE_ON[ES+RS-1:ES] + 1'b1;
    else
        R_O = LE_ON[ES+RS-1:ES];
end
endmodule