/////////////////////////////////////////////////////////////////////
// Design unit: Posit Division Arithmetic
//            :
// File name  : DIV_Arithmetic.sv
//            :
// Description:
//            :
// Limitations:
//            :
// System     : SystemVerilog IEEE 1800-2005
//            :
// Author     : Xiaoan(Jasper) He   Letian(Brian) Chen
//            : xh2g20@soton.ac.uk  lc1e20@soton.ac.uk
//
// Revision   : Version 1.0 25/10/2023
/////////////////////////////////////////////////////////////////////
timeunit 1ns;
timeprecision 1ps;
module Arithmetic_FMA #(parameter N = 32, parameter ES = 2, parameter RS = $clog2(N))
  (
    input  logic signed Sign1, Sign2, Sign3,
    input  logic signed [RS+2:0] k1,k2,k3,
    input  logic [ES-1:0] Exponent1, Exponent2, Exponent3,
    input  logic [N-1:0] Mantissa1, Mantissa2, Mantissa3,
    input  logic signed [N-2:0] InRemain1, InRemain2, InRemain3,
    input  logic inf1, inf2, inf3,
    input  logic zero1, zero2, zero3,
    output logic [2*N-1:0] FMA_Mant_N,
    output logic [ES+RS+1:0] LE_O,
    output logic [ES-1:0] E_O,
    output logic signed [RS+2:0] R_O, sumR,
    output logic inf, zero, Sign
  );
  int i; 
  logic LS, op, Greater_Than;
  logic inf_temp, zero_temp, Sign_temp;
  logic [2*N-1:0] Mult_Mant;
  logic [3*N-1:0] Mult_Mant_N,sft_mant3;
  logic signed [RS+2:0]sumE_Ovf;
  logic [ES:0] sumE, sumE_temp;  // 1 more bit then Exponent for Ovf
  logic signed [RS+2:0] R_O_temp, R_O_mult, sumR_temp;
  logic [ES-1:0] E_O_mult;

  logic [RS+2:0] LR, SR;
  logic [ES-1:0]LE, SE;
  logic [3*N-1:0]LM, SM;
  // logic [2*N-1:0] LM1, SM1;
  //  exponent difference 
  logic signed [RS+2:0] R_diff;
  logic [N-1:0] E_diff;
  // shifting accordingly and mantissa addition
  logic [3*N-1:0]SM_sft;
  logic [3*N:0] Add_Mant;
  logic [3*N-1:0] Add_Mant_sft;
  // post composition
  logic [N-1:0] LBD_in;
  logic Mant_Ovf;
  logic signed [RS:0] shift;
  logic [ES+RS+1:0] LE_ON;

  Leading_Bit_Detector_8B #(.N(N), .ES(ES)) LBD_8B (.In(LBD_in), .EndPosition(shift));

  always_comb
  begin
    // mult part
    //  check infinity and zero
    inf_temp = inf1 | inf2;
    zero_temp = zero1 | zero2;

        /////      MULTIPLICATION ARITHMETIC       //////
    Sign_temp = Sign1 ^ Sign2;

    //  Mantissa Multiplication Handling
    Mult_Mant = Mantissa1 * Mantissa2;



    if(Mult_Mant[2*N-1])
    Mult_Mant_N = Mult_Mant << N;
    else
    Mult_Mant_N = Mult_Mant << N+1;

    if(sumR[RS+2])
    sumE_temp = Exponent1+Exponent2 + Mult_Mant[2*N-1];
    else
    sumE_temp = Exponent1+Exponent2 + Mult_Mant[2*N-1];

    sumE_Ovf = {{RS+1{1'b0}}, sumE_temp[ES]};
    sumR_temp = k1+k2+sumE_Ovf;
    if(sumR[RS+2]) // negtaive exponent
    begin
      E_O_mult = sumE_temp[ES-1:0];
      // R_O_mult = -sumR_temp;
    end
    else            // positive exponent
    begin
      E_O_mult = sumE_temp[ES-1:0];
      // R_O_mult = sumR_temp + 1'b1;
    end

        //////          ADDITION ARITHMETIC         //////
    inf = inf_temp | inf3;
    zero = zero_temp & zero3;
    
    op = Sign_temp ~^ Sign3;

    sft_mant3 = Mantissa3 << 2*N;

    if(sumR_temp > k3)
      Greater_Than = 1;
    else if (sumR_temp == k3 && E_O_mult > Exponent3)
      Greater_Than = 1;
    else if (sumR_temp == k3 && E_O_mult == Exponent3 && Mult_Mant_N > sft_mant3)
      Greater_Than = 1;
    else
      Greater_Than = 0;
    
    // Assign components to corresponding logic, L - Large S - Small
    LS  = Greater_Than ? Sign_temp : Sign3;
    LR  = Greater_Than ? sumR_temp : k3;
    LE  = Greater_Than ? E_O_mult : Exponent3;
    LM  = Greater_Than ? Mult_Mant_N : sft_mant3; // MSB for overflow detection
    SR  = Greater_Than ? k3 : sumR_temp;
    SE  = Greater_Than ? Exponent3 : E_O_mult;
    SM  = Greater_Than ? sft_mant3 : Mult_Mant_N;

    Sign = LS;

    //// Mantissa Addition ////
    // find the regime difference
    R_diff = LR - SR;

    // total exponent difference
    E_diff = (R_diff*(2**(ES))) + (LE - SE); 
    // LM1 = {LM, {N{1'b0}}};
    // SM1 = {SM, {N{1'b0}}};

    // if(E_diff > 64)
    //     SM_sft = SM1 >> 64;
    // else
    //     SM_sft = SM1 >> E_diff;

    if(E_diff > 64)
        SM_sft = SM >> 64;
    else
        SM_sft = SM >> E_diff;

    if(op)
        Add_Mant = LM + SM_sft;
    else
        Add_Mant = LM - SM_sft;
        
    Mant_Ovf = Add_Mant[3*N];
    
    // (MSB OR 2nd MSB) bit since LBD_IN is for leading bit
    LBD_in = {(Add_Mant[3*N] | Add_Mant[3*N-1]), Add_Mant[3*N-2:2*N]}; 

        if(Mant_Ovf)
        begin
            Add_Mant_sft = Add_Mant[3*N:1] << shift;
        end
        else
        begin
            Add_Mant_sft = Add_Mant[3*N-1:0] << shift;           
        end
        FMA_Mant_N = Add_Mant_sft;
        // Add_Mant_N[0] = Add_Mant_N[0]|Add_Mant[0];

        //////          Post Composition            //////
    //// Compute regime and exponent of final result  ////
    
    /* 
    Output exponent is mainly based on larger input
    also taking overflow and left shift into account
    */
    LE_O = {LR, LE} + Mant_Ovf - shift; 
    if (LE_O[RS+ES+1])    // -ve exponent
        LE_ON = -LE_O;
    else                // +ve exponent
        LE_ON = LE_O;

    if (LE_O[ES+RS+1] & |(LE_ON[ES-1:0])) // if -ve LE_O, last ES bits in LE_ON are not '0
        E_O = (1<<ES)-LE_ON[ES-1:0];
    else
        E_O = LE_ON[ES-1:0];

    if (~LE_O[ES+RS+1]) // +ve exponent, regime sequence w/1
        R_O = LE_ON[ES+RS:ES] + 1; // +1 due to K = m-1 w/1
    else if ((LE_O[ES+RS+1] & |(LE_ON[ES-1:0]))) // -ve exponent, regime sequence w/0, last ES bits in LE_ON are not '0
        R_O = LE_ON[ES+RS:ES] + 1'b1; // compensate 1 
    else    //-ve exponent, last ES bits in LE_ON are '0
        R_O = LE_ON[ES+RS:ES];    //  no compensation since 2's comp of 00 is 100, automatically conpensate
  end
endmodule
