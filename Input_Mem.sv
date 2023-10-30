module Input_Mem #(parameter DEPTH, parameter WIDTH) (clk, rst, write_en, addr, data_in, data_out);
  input clk, rst, write_en;
  input [$clog2(DEPTH) - 1 : 0] addr;
  input [WIDTH - 1 : 0] data_in;
  output [WIDTH - 1 : 0] data_out;
  
  reg [WIDTH - 1 : 0] MEM [DEPTH - 1 : 0];
  
  always @(posedge clk, posedge rst)begin
    if(rst)begin
      for(integer i = 0; i < DEPTH; i = i + 1)begin
	MEM[i] <= 0;
      end
    end
    else if(write_en)begin
      for(integer i = DEPTH - 1; i > 0; i = i - 1)
        MEM[i] <= MEM[i - 1];
      MEM[0] <= data_in;
    end
  end

  assign data_out = MEM[addr];
endmodule