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
timeunit 1ns; timeprecision 100ps;

module FMA_32Bit_ES2_tb;
parameter N = 32, RS = $clog2(N), ES = 2;

//input logic
logic signed [N-1:0] IN1, IN2, IN3;
logic op_N, op_sub;

//output logic
logic signed [N-1:0] OUT;

FMA #(.N(N), .ES(ES)) Fused_Mutiply_Add (.*);


logic clk;
integer outfile;
logic start;
logic [N-1:0] data1 [1:8200];
logic [N-1:0] data2 [1:8200];
logic [N-1:0] data3 [1:8200];
initial $readmemb("IN1_8200_Posit.txt",data1);
initial $readmemb("IN2_8200_Posit.txt",data2);
initial $readmemb("IN3_8200_Posit.txt",data3);
// logic [N-1:0] data1 [1:400000];
// logic [N-1:0] data2 [1:400000];
// logic [N-1:0] data3 [1:400000];
// initial $readmemb("IN1_8200_Posit.txt",data1);
// initial $readmemb("IN2_8200_Posit.txt",data2);
// initial $readmemb("IN3_8200_Posit.txt",data3);
// logic [N-1:0] data1 [1:800000];
// logic [N-1:0] data2 [1:800000];
// logic [N-1:0] data3 [1:800000];
// initial $readmemb("full_range_in1.txt",data1);
// initial $readmemb("full_range_in2.txt",data2);
// initial $readmemb("full_range_in3.txt",data3);

logic [20:0] i;
logic [15:0] error_count;
	initial begin
		// Initialize Inputs
		IN1 = 0;
		IN2 = 0;
		IN3 = 0;
		clk = 0;
		start = 0;
		op_N = 0;
		op_sub = 0;
	
		
		// Wait 100 ns for global reset to finish
		#100 i=0;
        error_count = 0;
		#20 start = 1;
                #8100115 start = 0;
		#100;
		
		$fclose(outfile);
		$stop;
		// $finish;
		
	end

 always #5 clk=~clk;

  always @(posedge clk) 
  begin			
 	IN1=data1[i];	
	IN2=data2[i];
	IN3=data3[i];
	if(i==20'd800002)
	$stop;
  	    //   $finish;
	else i = i + 1;
 end


initial outfile = $fopen("error_32bit.txt", "wb");

logic [N-1:0] result [1:8200];
initial $readmemb("fma_8200_result.txt",result);
// logic [N-1:0] result [1:400000];
// initial $readmemb("fma_8200_result.txt",result);
// logic [N-1:0] result [1:800000];
// initial $readmemb("full_range_result.txt",result);
logic [N-1:0] show_result, show_result_neg;
logic [N-1:0] diff;
assign diff = (result[i-1] > OUT) ? result[i-1]-OUT : OUT-result[i-1];
always @(posedge clk) 
begin
        show_result = result[i-1];
		show_result_neg = -result[i-1];
     	// diff = (result[i-1] > OUT) ? result[i-1]-OUT : OUT-result[i-1];
     	//$fwrite(outfile, "%h\t%h\t%h\t%h\t%d\n",in1, in2, out,result[i-1],diff);
        if(diff)
        error_count += 1;
        else
        error_count =error_count;
     	$fwrite(outfile, "%d\n",diff);
end
endmodule