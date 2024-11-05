`timescale 1ns / 1ps
module myFIR_tb();
  parameter LENGTH = 64;
  parameter WIDTH = 16;
  parameter OUT_WIDTH = 38;
  parameter TEST_LENGTH = 1000;

  reg [WIDTH - 1 : 0] FIR_input;
  wire [37:0] FIR_output;
  reg [37:0] MATLAB_Result;

  reg clk, rst, input_valid, output_valid;

  integer i, fp;

  FIR #(LENGTH, WIDTH, OUT_WIDTH) UUT(.clk(clk), .rst(rst), .input_valid(input_valid), .output_valid(output_valid),
	.FIR_input(FIR_input), .FIR_output(FIR_output));
	
  reg [WIDTH - 1 : 0] Input_mem [TEST_LENGTH - 1 : 0];
	
  initial begin  
      $readmemb("inputs.txt", Input_mem);
  end

  reg [37:0] Out_comp_mem [TEST_LENGTH - 1 : 0];
	
  initial begin  
      $readmemb("outputs.txt", Out_comp_mem);
  end

	
  initial begin
    clk = 1'b0;
  end

  always #10 clk = ~clk;

  initial begin
    rst = 1'b0;
    #55
    rst = 1'b1;
    #30
    rst = 1'b0;
  end

  initial begin
    input_valid = 1'b0;
    #105
    input_valid = 1'b1;
    #20
    input_valid = 1'b0;
  end

  initial begin
    fp = $fopen("test.txt");
    #125;
    $display("Testing Samples...");		
    for(i = 0; i < TEST_LENGTH - 1; i = i + 1)begin
      FIR_input <= Input_mem[i];
      input_valid = 1'b0;
      #105
      input_valid = 1'b1;
      #20
      input_valid = 1'b0;
      @(posedge output_valid)
        MATLAB_Result <= Out_comp_mem[i];
	#10
	$fwrite(fp, "FILTER_RESULT:%d			MATLAB_RESULT:		%d\n", FIR_output, MATLAB_Result);
    end
      #500
  $fclose(fp);
  $display ("Test Passed.");
  $stop;
  end

  //Assertions
  property pr1;
	@(posedge clk) $rose(input_valid) |=> ##65 $rose(output_valid);
  endproperty

  InOutInterval: assert property (pr1) $display($stime,,,"\t\t %m PASS"); else $display($stime,,,"\t\t %m FAIL");;
  
  sequence sr2(a,b);
   a ##1 b;
  endsequence
  
  property pr2 (logic[2:0] ps, logic [2:0]state, logic signal1, logic signal2);
   @(posedge clk) (ps == state) |-> sr2(signal1, signal2) or not(signal1) ;
  endproperty

  testStateFiltering1: assert property (pr2(UUT.CU.ps, 3'd2, UUT.CU.Co, output_valid)) begin $display($stime,,,"\t\t %m PASS");end else begin
   $display($stime,,,"\t\t %m FAIL"); end

  property pr3(valid, data);
	@(posedge clk) (valid ) |-> !($isunknown(data));
  endproperty

  input_is_known: assert property (pr3(.valid(input_valid), .data(FIR_input)))
  $display($stime,,,"\t\t %m PASS"); else $display($stime,,,"\t\t %m FAIL"); 

  property pr4;
	@(posedge clk) (UUT.write_en ) |=> (UUT.DP.FIR_input == Input_mem[i]);
  endproperty
 
  input_memory: assert property (pr4)
  $display($stime,,,"\t\t %m PASS"); else $display($stime,,,"\t\t %m FAIL");

  property pr5 (logic [2:0] ps, logic [2:0] state, logic signal);
   @(posedge clk) (ps == state) |-> signal;
  endproperty

  testStateFiltering2: assert property (pr5(UUT.CU.ps, 3'd1, UUT.CU.write_en)) begin $display($stime,,,"\t\t %m PASS");end else begin
    $display($stime,,,"\t\t %m FAIL"); end
endmodule