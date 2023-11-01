/////////////////////////////////////////////////////////////////////
// Design unit: Posit Adder Testbench
//            :
// File name  : Posit_Adder_32bits_tb-2.sv
//            :
// Description: Test N-bit Posit Adder/Subtractor with ES-bit Exponent
//            :
// Limitations: None
//            : 
// System     : SystemVerilog IEEE 1800-2005
//            :
// Author     : Xiaoan(Jasper) He 
//            : xh2g20@ecs.soton.ac.uk
//
// Revision   : Version 1.2 25/10/2023
/////////////////////////////////////////////////////////////////////
timeunit 1ns; timeprecision 1ps;

module Posit_Adder_32Bit_es2_tb;
parameter N = 32, RS = $clog2(N), ES = 2;

//	Input logic
logic signed [N-1:0] IN1, IN2, tmp_in1, tmp_in2, OUT1,OUT2;

//	Output logic
logic signed [N-1:0] OUT;

Optimised_PA #(.N(N), .ES(ES)) OPA_tb (.*);

//	Other Logic
logic clk;
logic start;
logic [18:0] i;
logic [15:0] error_count;
logic [N-1:0] data1 [1:210000];
logic [N-1:0] data2 [1:210000];
initial $readmemb("IN1_210k_Posit.txt",data1);
initial $readmemb("IN2_210k_Posit.txt",data2);
logic signed [N-1:0] result [1:210000];
logic [N-1:0] show_result, show_result_neg;
initial $readmemb("AddSub_R210k.txt",result);
logic signed [N-1:0] diff;
integer outfile;
integer outfile2;

	initial 
    begin
		// Initialize Inputs
		IN1 = 0;
		IN2 = 0;
		clk = 0;
		start = 0;
	
		
		// Wait 100 ns for global reset to finish
		#100 i=0;
             error_count = 0;
		#20 start = 1;
                #210011500 start = 0;
		#100;
		
		$fclose(outfile);
		// $fclose(outfile2);
		$finish;
	end

 always #5 clk=~clk;

initial outfile = $fopen("adder_error_32bit.txt", "wb");
initial outfile2 = $fopen("adder_error_full_32bit.txt", "wb");

assign diff = (result[i-1] > OUT) ? result[i-1]-OUT : OUT-result[i-1];
  always @(posedge clk) 
  begin			
 	IN1=data1[i];	
	IN2=data2[i];
    show_result = result[i];
	show_result_neg = -result[i];
    // diff = result[i-1]-OUT;
    if(diff)
    error_count = error_count+1;
    else
    error_count = error_count;
    $fwrite(outfile, "%d\n",diff);
	// $fwrite(outfile2, "%b -------- %b\n", OUT, show_result);
	if(i==19'd210002)
	begin
		$stop;
  	    $finish;
	end
	else i = i + 1;
    end
endmodule