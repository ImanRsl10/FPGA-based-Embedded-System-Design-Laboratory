module Shift_Reg16(clk, rst, ld, inp , outp);
	input clk, rst, ld;
	input[15:0] inp;
	output reg[7:0] outp;

	reg count;

	always@(posedge clk)begin
		if(rst) begin
			count = 1'b0; outp <= 8'b0;
		end
		else if(ld) begin
			outp = inp[count*8+:7]; count <= count + 1'b1;
		end
	end

endmodule
