/////////////////////////////////////////////////////////////////////
// Design unit: Posit Adder Testbench
//            :
// File name  : Posit_Adder_32bits_tb-4.sv
//            :
// Description: Test Posit Adder
//            :
// Limitations: None
//            : 
// System     : SystemVerilog IEEE 1800-2005
//            :
// Author     : Xiaoan(Jasper) He 
//            : xh2g20@ecs.soton.ac.uk
//
// Revision   : Version 1.0 20/02/2023
/////////////////////////////////////////////////////////////////////

timeunit 1ns; timeprecision 1ps;

module Posit_Adder_32Bit_es2_tb;
parameter N = 32, RS = $clog2(N), ES = 2;

//input logic
logic signed [N-1:0] IN1, IN2, tmp_in1, tmp_in2, OUT1,OUT2,diff;

//output logic
logic signed [N-1:0] OUT;

Optimised_PA #(.N(N), .ES(ES)) OPA_tb (.*);

logic clk;
// bit [N-1:0]outf [100];
integer outfile;
integer outfile2;

logic start;
logic [N-1:0] data1 [1:8200];
logic [N-1:0] data2 [1:8200];
initial $readmemb("in1_32e2.txt",data1);
initial $readmemb("in2_32e2.txt",data2);
logic [N-1:0] result [1:65536];
logic [N-1:0] show_result;
initial $readmemb("answer_32e2.txt",result);

logic [15:0] i;
logic [15:0] error_count;
	
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
                #655500 start = 0;
		#100;
		
		$fclose(outfile);
		$fclose(outfile2);
		$finish;
	end

 always #5 clk=~clk;

initial outfile = $fopen("adder_error_32bit.txt", "wb");
initial outfile2 = $fopen("adder_error_full_32bit.txt", "wb");

  always @(posedge clk) 
  begin			
 	IN1=data1[i];	
	IN2=data2[i];
    show_result = result[i];
    diff = (result[i-1] > OUT) ? result[i-1]-OUT : OUT-result[i-1];
    if(diff)
    error_count = error_count+1;
    else
    error_count = error_count;
    $fwrite(outfile, "%d\n",diff);
	$fwrite(outfile2, "%b -------- %b\n", OUT, show_result);
	if(i==16'hffff)
  	      $finish;
	else i = i + 1;
    end

// reg [N-1:0] result [1:65536];
// reg [N-1:0] show_result;
// initial $readmemb("answer_32e2.txt",result);
// always @(posedge clk) 
// begin
// 	if(start)
//     begin
//         show_result = result[i-1];
//      	diff = (result[i-1] > OUT) ? result[i-1]-OUT : OUT-result[i-1];
//      	//$fwrite(outfile, "%h\t%h\t%h\t%h\t%d\n",in1, in2, out,result[i-1],diff);
//      	$fwrite(outfile, "%d\n",diff);
//      	end
// end
endmodule