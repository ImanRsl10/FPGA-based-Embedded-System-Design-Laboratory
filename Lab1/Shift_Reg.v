module Shift_Reg(clk, rst, ld, inp , outp);
	input clk, rst, ld;
	input [7:0]inp;
	output reg[15:0] outp;

	always@(posedge clk)begin
		if(rst) outp = 16'b0;
		else if(ld) outp = {outp[7:0], inp};
	end 
endmodule
