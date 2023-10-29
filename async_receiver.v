module async_receiver(
    input clk,
    input rst,
    input RxD_in,
    output reg RxD_data_ready,
    output reg [7:0] RxD_data  // data received, valid only (for one clock cycle) when RxD_data_ready is asserted
);

    parameter ClkFrequency = 50000000;
    parameter Baud = 115200;
    parameter Oversampling = 4;	// needs to be a power of 2

    wire BaudTick, co1, co2, RxD, co;
    wire [2:0] count;
    reg sh_en1, sh_en2, clr1, clr2;
    reg enable;
    reg [1:0] count1;
    reg [3:0] count2;

    reg [2:0] ps, ns;
    parameter [2:0] idle = 3'b000, start = 3'b001, counter = 3'b010, transmit = 3'b011, RxD_ready = 3'b100;

    BaudTickGen #(ClkFrequency, Baud, Oversampling) tickgen4(clk, rst, 1'b0, BaudTick);
    overSamplingHandler handler(.clk(clk), .rst(rst), .RxD_raw(RxD_in), .BaudTick(BaudTick), .RxD(RxD), .co(co), .count(count));

    always @(ps, co2, RxD, BaudTick) begin
        case(ps)
            idle: ns = RxD ? idle : transmit;
            //start: ns = RxD ? counter : transmit; //start;
			// counter: ns = transmit;
            transmit: begin ns = co2 ? RxD_ready : transmit; RxD_data <= co ? {RxD, RxD_data[7:1]} : RxD_data; end 
            RxD_ready: begin ns = idle; RxD_data_ready = 1'b1; end
        endcase
    end

    always @(ps) begin
        {enable, RxD_data_ready, sh_en1, sh_en2, clr1, clr2} = 6'b0;
        case(ps)
            idle: {clr1, clr2} = 2'b11;
			//counter: enable = 1'b1;
            transmit: begin ns = co2 ? RxD_ready : transmit; RxD_data <= co ? {RxD, RxD_data[7:1]} : RxD_data; end //Co
            RxD_ready: begin ns = idle; RxD_data_ready = 1'b1; end
        endcase
    end

    always @(posedge clk) begin
        if(rst) ps <= idle;
        else ps <= ns;
    end

    always @(posedge clk) begin
        if(rst) count1 <= 2'b00;
        else if(BaudTick & (count == 3'b011)) count1 <= count1 + 1'b1;
    end

    always @(posedge clk) begin
        if(rst | co2) count2 <= 4'b0;
        else if(BaudTick & (count == 3'b011)) count2 <= count2 + 1'b1;
    end

    assign co1 = &count1;
    assign co2 = (count2 == 4'b1001);

endmodule
