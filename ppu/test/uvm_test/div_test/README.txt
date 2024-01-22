Posit_Divider_32bits_tb.sv		=>	Testbench for FMA module (can do only add/sub or mult by disabling inputs)

IN1_8200.txt / IN2_8200.txt / IN3_8200.txt / divider_result.txt
minor test within full range but only 8200 sets of sequences

mid_range_in1.txt / mid_range_in2.txt / mid_range_div_result.txt
400,000 test sequences mainly focus on 2^(-20) to 2^16, where Posit performs better, giving the higher precision

full_range_in1.txt / full_range_in2.txt / full_range_div_result.txt
800,000 test sequences in ranges other than 2^(-20) to 2^16

error_32bit
Generated from the testbench, show the difference (in bits) between outcome from the module and softposit result