module FIR_tb();

  parameter IN_WIDTH = 16;
  parameter OUT_WIDTH = 38;
  parameter DATA_LEN = 150000;
  reg [IN_WIDTH - 1:0] din;
wire  [OUT_WIDTH-1:0] dout;

reg [OUT_WIDTH-1:0] expected_data [0 : DATA_LEN];
reg [IN_WIDTH-1:0] input_data [0 : DATA_LEN];
reg [OUT_WIDTH-1:0] temp_out;
reg clk,RST_n, in_val;
wire out_val;
integer i;

FIR#(64, IN_WIDTH, OUT_WIDTH) UUT(.clk(clk), .rst(RST_n), .FIR_input(din), .input_valid(in_val),
    .FIR_output(dout), .output_valid(out_val));

initial
    begin  
    $readmemb("inputs.txt", input_data);   
end

initial
    begin
    $readmemb("outputs.txt", expected_data);
end           

initial
begin
	clk = 1'b0;
end

always #10 clk = ~clk;

initial
   begin 
	RST_n = 1'b1;
   din = 16'b0;   
   #400;
   RST_n = 1'b0;
end         

initial
begin
  #400;
	#20;
	$display("Testing %d Samples...",DATA_LEN);		
	for(i = 0; i < DATA_LEN; i = i + 1)
	begin
		din =input_data[i];
		
		#20 in_val = 1'b1;

		#20 in_val = 1'b0;
		
		@(posedge out_val)
		#20;
	end
	$stop;
end
endmodule