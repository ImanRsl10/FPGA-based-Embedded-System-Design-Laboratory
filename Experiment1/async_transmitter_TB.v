module async_transmitter_TB();
	reg clk = 1'b1, TxD_start = 1'b0;
	reg [7:0] TxD_data;
	wire TxD, TxD_busy;

	async_transmitter TR(clk, TxD_start, TxD_data, TxD, TxD_busy);

	always #10 clk = ~clk;

	initial begin
		#21 TxD_data = 8'b00101111;
		#21;
		#21 TxD_start = 1'b1;
		#21 TxD_start = 1'b0;
		#104000 TxD_data = 8'b10101010;
		#21;
		#21 TxD_start = 1'b1;
		#21 TxD_start = 1'b0;
		#104000;
		 $stop;
	end
endmodule
