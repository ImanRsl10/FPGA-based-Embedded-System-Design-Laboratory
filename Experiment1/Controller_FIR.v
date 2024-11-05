module Controller_FIR(clk, rst, data_ready, output_valid, busy, input_valid, TxD_start, ldFFrxd, ldFFtxd);
	input clk, rst, data_ready, output_valid, busy;
	output reg ldFFrxd, ldFFtxd, input_valid, TxD_start;

	reg [1:0] count;	
	reg cnt;
	wire co;

	reg [2:0] ps, ns;
	parameter[2:0] idle = 3'b000, load_recieve = 3'b001, hold = 3'b010, FIR = 3'b011, load_transmit = 3'b100, hold_transmit = 3'b101, transmit = 3'b110; 
	 
	always@(ps, data_ready, output_valid, busy, co)begin
		{ldFFrxd, ldFFtxd, input_valid, TxD_start, cnt} = 5'b0;
		case(ps)
		idle: ns = co ? FIR : data_ready ? load_recieve : idle;
		load_recieve: begin cnt = 1'b1; ldFFrxd = 1'b1; ns = co ? FIR : idle; end
		//hold: begin ldFFrxd = 1'b1; ns = FIR; end
		FIR: begin input_valid = 1'b1; ns = output_valid ? load_transmit : FIR; end
		load_transmit: begin cnt = 1'b1; ldFFtxd = 1'b1; ns = hold_transmit; end
		hold_transmit: begin TxD_start = 1'b1; ns = co ? idle : transmit; end
		transmit: begin ns = busy ? transmit : load_transmit; end
		endcase
	end

	always@(posedge clk, posedge rst)begin
		if(rst) ps <= idle;
		else ps <= ns;
	end

	always@(posedge clk) begin
		if(rst | co) count = 2'b0;
		else if(cnt) count = count + 1;
	end
	assign co = (count == 2'b10) ? 1'b1 : 1'b0;
endmodule
