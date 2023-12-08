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
// Author     : Xiaoan(Jasper) He 
//            : xh2g20@soton.ac.uk
//
// Revision   : Version 1.3 /10/2023
//            : Version 1.4 /11/2023    2N-bit lengthened Add_Mant 
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
    output logic [2*N:0] Add_Mant,
    output logic [2*N-1:0] Add_Mant_N,
    output logic signed [ES+RS:0] LE_O,
    output logic [ES-1:0] E_O,
    output logic signed [RS:0] R_O,
    output logic LS , inf, zero, Sign
);

//////      VARIABLE DECLERATION     //////
// logic inf, zero;
logic op;
// components to corresponding logic, L - Large S - Small
logic Greater_Than;
logic [RS:0] LR, SR;

logic [ES-1:0]LE, SE;
logic [N-1:0]LM, SM;
logic [2*N-1:0] LM1, SM1;
//  exponent difference 
logic signed [RS:0] R_diff;
logic [N-1:0] E_diff;
// shifting accordingly and mantissa addition
logic [2*N-1:0]SM_sft, Mant_Kper;
logic SM_add;
logic [2*N-1:0] Add_Mant_sft;
logic [2*N:0] Add_Mant_tmp;
// post composition
logic [N-1:0] LBD_in;
logic Mant_Ovf;
logic signed [RS:0] shift;
logic [ES+RS:0] LE_ON;

Leading_Bit_Detector_8B #(.N(N), .ES(ES)) LBD_8B (.In(LBD_in), .EndPosition(shift));
assign Sign = LS;
always_comb
begin
    // check infinity and zero
    inf     = inf1 | inf2;
    zero    = zero1 & zero2;

    //////          ADDITION ARITHMETIC         //////

    // Confirm  addition or subtraction (s1 XNOR s2)
    op = Sign1 ~^ Sign2 ;

    // Find the greater InRemain
    Greater_Than = (InRemain1[N-2:0] >  InRemain2[N-2:0])? 1'b1 : 1'b0;

    // Assign components to corresponding logic, L - Large S - Small
    LS  = Greater_Than ? Sign1 : Sign2;
    LR  = Greater_Than ? k1 : k2;
    LE  = Greater_Than ? Exponent1 : Exponent2;
    LM  = Greater_Than ? Mantissa1 : Mantissa2; // MSB for overflow detection
    SR  = Greater_Than ? k2 : k1;
    SE  = Greater_Than ? Exponent2 : Exponent1;
    SM  = Greater_Than ? Mantissa2 : Mantissa1;

    //// Mantissa Addition ////
    // find the regime difference
    R_diff = LR - SR;

    // total exponent difference
    E_diff = (R_diff*(2**(ES))) + (LE - SE); 
    LM1 = {LM, {N{1'b0}}};
    SM1 = {SM, {N{1'b0}}};

    if(E_diff > 64)
        SM_sft = SM1 >> 64;
    else
        SM_sft = SM1 >> E_diff;

    if(op)
        Add_Mant = LM1 + SM_sft;
    else
        Add_Mant = LM1 - SM_sft;
        
    Mant_Ovf = Add_Mant[2*N];

    /*
     In the case of subtraction between two close numbers
     MSBs may lost, it is useful to detect the 
     Leading ONE and left shift accordingly
    */
    
    // (MSB OR 2nd MSB) bit since LBD_IN is for leading bit
    LBD_in = {(Add_Mant[2*N] | Add_Mant[2*N-1]), Add_Mant[2*N-2:N]}; 

        if(Mant_Ovf)
        begin
            Add_Mant_sft = Add_Mant[2*N:1] << shift;
        end
        else
        begin
            Add_Mant_sft = Add_Mant[2*N-1:0] << shift;           
        end
        Add_Mant_N = Add_Mant_sft;
        // Add_Mant_N[0] = Add_Mant_N[0]|Add_Mant[0];

        //////          Post Composition            //////
    //// Compute regime and exponent of final result  ////
    
    /* 
    Output exponent is mainly based on larger input
    also taking overflow and left shift into account
    */
    LE_O = {LR, LE} + Mant_Ovf - shift; 
    if (LE_O[RS+ES])    // -ve exponent
        LE_ON = -LE_O;
    else                // +ve exponent
        LE_ON = LE_O;

    if (LE_O[ES+RS] & |(LE_ON[ES-1:0])) // if -ve LE_O, last ES bits in LE_ON are not '0
        E_O = (1<<ES)-LE_ON[ES-1:0];
    else
        E_O = LE_ON[ES-1:0];

    if (~LE_O[ES+RS]) // +ve exponent, regime sequence w/1
    R_O = LE_ON[ES+RS-1:ES] + 1; // +1 due to K = m-1 w/1
    else if ((LE_O[ES+RS] & |(LE_ON[ES-1:0]))) // -ve exponent, regime sequence w/0, last ES bits in LE_ON are not '0
        R_O = LE_ON[ES+RS-1:ES] + 1'b1; // compensate 1 
    else    //-ve exponent, last ES bits in LE_ON are '0
        R_O = LE_ON[ES+RS-1:ES];    //  no compensation since 2's comp of 00 is 100, automatically conpensate
end
endmodule