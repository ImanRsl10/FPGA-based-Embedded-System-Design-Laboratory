module Top(CLOCK_50, rst, data_ready, inp, outp);
	input CLOCK_50, rst, data_ready;
	input [7:0] inp;
	output outp;

	wire busy, ldFFrxd, ldFFtxd, input_valid, output_valid, TxD_start;
	wire [7:0] address, TxD;
	wire[16:0] FIR_input, FIR_output, Coef;

	Shift_Reg shreg(.clk(CLOCK_50), .rst(rst), .ld(ldFFrxd), .inp(inp) , .outp(FIR_input));

	Controller_FIR CU(.clk(CLOCK_50), .rst(rst), .data_ready(data_ready), .output_valid(output_valid), .busy(busy), .input_valid(input_valid), .TxD_start(TxD_start), .ldFFrxd(ldFFrxd), .ldFFtxd(ldFFtxd));

	FIR #(64, 16, 38) FILTER(.clk(CLOCK_50), .rst(rst), .FIR_input(FIR_input), .input_valid(input_valid), .addr(address), .FIR_output(FIR_output), .output_valid(output_valid), .Coef(Coef));
	Coeff_ROM #(64, 16) ROM(.addr(address), .Coeff_out(Coef));

	Shift_Reg16 shreg2(.clk(CLOCK_50), .rst(rst), .ld(ldFFtxd), .inp(FIR_output), .outp(TxD));
	async_transmitter TXD(.CLOCK_50(CLOCK_50), .rst(rst), .TxD_start(TxD_start), .SW(TxD), .UART_TXD(outp), .LEDG(busy));
	
endmodule
