module LAB1_top(CLOCK_50, SW, LEDG, LEDR, UART_TXD);

input CLOCK_50;
input [9:0] SW;
output [1:0] LEDG;
output [7:0] LEDR;
output UART_TXD;

wire data;

	//rxd_data = txd_data // rxd_data_ready //txd_busy
	async_transmitter TR(CLOCK_50, SW[9:0], UART_TXD, LEDG[1]);
	async_receiver RC(CLOCK_50, SW[0], data, LEDG[0], LEDR[7:0]);
	
assign data = UART_TXD;
endmodule
