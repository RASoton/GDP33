/////////////////////////////////////////////////////////////////////
// Design unit: Posit Multiplier Testbench
//            :
// File name  : Posit_multiplier_32bits_tb.sv
//            :
// Description: Test 32-bit Posit Multiplier
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

module Posit_Adder_32Bit_ES4_tb;
parameter N = 32, RS = $clog2(N), ES = 2;


//input logic
logic signed [N-1:0] IN1, IN2;

//output logic
logic signed [N-1:0] OUT;

Optimised_PM #(.N(N), .ES(ES)) Posit_Mult (.*);

logic clk;
integer outfile;
logic start;
logic [N-1:0] data1 [1:8200];
logic [N-1:0] data2 [1:8200];
initial $readmemb("in1_fin.txt",data1);
initial $readmemb("in2_fin.txt",data2);

logic [15:0] i;
logic [15:0] error_count;
	initial begin
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
		$finish;
	end

 always #5 clk=~clk;

  always @(posedge clk) 
  begin			
 	IN1=data1[i];	
	IN2=data2[i];
	if(i==16'hffff)
  	      $finish;
	else i = i + 1;
 end


initial outfile = $fopen("error_32bit.txt", "wb");

logic [N-1:0] result [1:65536];
logic [N-1:0] show_result;
initial $readmemb("mult_result_v1.txt",result);
logic [N-1:0] diff;
assign diff = (result[i-1] > OUT) ? result[i-1]-OUT : OUT-result[i-1];
always @(posedge clk) 
begin
        show_result = result[i-1];
     	// diff = (result[i-1] > OUT) ? result[i-1]-OUT : OUT-result[i-1];
     	//$fwrite(outfile, "%h\t%h\t%h\t%h\t%d\n",in1, in2, out,result[i-1],diff);
        if(diff)
        error_count += 1;
        else
        error_count =error_count;
     	$fwrite(outfile, "%d\n",diff);
   
end


endmodule