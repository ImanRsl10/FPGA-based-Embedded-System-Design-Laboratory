module Register #(parameter WIDTH) (clk, rst, clr, ld, data_in, data_out);
  input clk, rst, clr, ld;
  input [WIDTH - 1 : 0] data_in;
  output reg [WIDTH - 1 : 0] data_out;
  
  always @(posedge clk, posedge rst)begin
    if(rst)
	  data_out <= 0;
    else if(clr)
	  data_out <= 0;
    else if(ld)
	  data_out <= data_in;
  end
endmodule