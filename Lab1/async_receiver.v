module async_receiver(clk, rst, RxD_in, RxD_data_ready, RxD_data);
    input clk, rst, RxD_in;
    output reg RxD_data_ready;
    output reg [7:0] RxD_data;  // data received, valid only (for one clock cycle) when RxD_data_ready is asserted

    parameter ClkFrequency = 50000000;
    parameter Baud = 115200;
    parameter Oversampling = 4;	// needs to be a power of 2

    wire BaudTick, co1, RxD, co;
    reg sh_en, cnt_en;
    reg [3:0] count1;
	
    reg [1:0] ps, ns;
    parameter [1:0] idle = 2'b00, transmit = 2'b01, RxD_ready = 2'b10;

    BaudTickGen #(ClkFrequency, Baud, Oversampling) tickgen4(clk, rst, 1'b0, BaudTick);
    overSamplingHandler handler(.clk(clk), .rst(rst), .RxD_raw(RxD_in), .BaudTick(BaudTick), .RxD(RxD), .co(co));

    always @(ps, RxD, co, co1) begin
        case(ps)
            idle: ns <= (~RxD & co) ? transmit : idle;
            transmit: ns <= co1 ? RxD_ready : transmit;
            RxD_ready: ns <= idle;
        endcase
    end

    always @(ps) begin
	 {RxD_data_ready, sh_en, cnt_en} = 3'b0;
        case(ps)
				transmit: {sh_en, cnt_en} = 2'b11;
            RxD_ready: RxD_data_ready = 1'b1;
        endcase
    end

    always @(posedge clk) begin
        if(rst)
            ps <= idle;
        else
            ps <= ns;
    end

    always @(posedge clk) begin
        if(rst | co1)
            count1 <= 4'b0;
	else if(co & cnt_en)
            count1 <= count1 + 1'b1;
    end

    always @(posedge clk)begin
		if(rst)
            RxD_data <= 8'b0;
		else if(co & sh_en)
            RxD_data <= {RxD, RxD_data[7:1]};
        else
            RxD_data <= RxD_data;
    end

    assign co1 = (count1 == 4'b1000);

endmodule