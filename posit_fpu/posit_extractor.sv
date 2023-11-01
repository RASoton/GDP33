
module posit_extractor #(parameter N=32, parameter ES=2, parameter RS = $clog2(N));

  typedef struct packed {
    logic signed sign;
    logic signed [RS:0] regime;
    logic [ES-1:0] exponent;
    logic [N-1:0] fraction;
    logic signed [N-2:0] remain;
    logic NaR;
    logic zero;
  } posit_result_t;

  typedef struct packed {
    logic [RS:0] EndPosition;
    logic RegimeCheck;
  } lb_detector_result_t;

  function lb_detector_result_t leading_bit_detector (input logic [N-2:0] remain);
    lb_detector_result_t result;
    int i;
    result.RegimeCheck = remain[N-2];
    result.EndPosition = 1'b1; 
    for(i = 1; i < (N-1); i++) 
    begin
        if (result.RegimeCheck == remain[((N-2)-i)])
            result.EndPosition = result.EndPosition + 1'b1;
        else 
            break;
    end
    return result;
  endfunction

  function posit_result_t extract(logic signed [N-1:0] In);
    automatic posit_result_t result;

    automatic logic zero_check;
    automatic logic [N-2:0] ShiftedRemain;
    automatic logic [(N-1)-1-(N-ES-2)-1:0] ZEROs;
    automatic int i;

    automatic lb_detector_result_t lb_result = leading_bit_detector(In[N-2:0]);

    ZEROs = '0;
    zero_check = |In[N-2:0];
    result.NaR = In[N-1] & (~zero_check);
    result.zero = ~(In[N-1] | zero_check);
    result.sign = In[N-1];

    if (result.sign)
        result.remain = -In[N-2:0];
    else   
        result.remain = In[N-2:0];
    if(result.zero)
        result.regime = 0;
    else if (lb_result.RegimeCheck)
        result.regime = lb_result.EndPosition - 1'b1;
    else 
        result.regime = -lb_result.EndPosition;
    ShiftedRemain = result.remain << (lb_result.EndPosition + 1'b1);
    result.exponent = ShiftedRemain[N-2:((N-1)-ES)];
    result.fraction = {1'b1, ShiftedRemain[N-ES-2:0], ZEROs};
    return result;
    endfunction

endmodule