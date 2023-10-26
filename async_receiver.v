module async_receiver(
    input CLOCK_50,
    input [0:0]SW,
    input UART_RXD,
    output reg [0:0]LEDG,
    output [7:0] LEDR  // data received, valid only (for one clock cycle) when LEDG is asserted
);

    parameter ClkFrequency = 50000000;
    parameter Baud = 115200;
    parameter Oversampling = 1;	// needs to be a power of 2
	 
	 reg [1:0] check;
	// assign LEDR[9:8] = check;
	 
	 reg [7:0] temp;
    wire BaudTick, co;
	 reg dummy;
    reg enable;
    reg [3:0] count;

    reg [2:0] ps, ns;
    parameter [2:0] idle = 3'b000, start = 3'b001, counter = 3'b010, transmit = 3'b011, RxD_ready = 3'b100;

    BaudTickGen #(ClkFrequency, Baud, Oversampling) tickgen4(CLOCK_50, SW[0], 1'b1, BaudTick);

    always @(ps, co, UART_RXD, BaudTick) begin
        {enable, LEDG} = 2'b0;
        case(ps)
            idle : begin ns = UART_RXD ? idle : start; LEDG = 1'b1; end
            start : begin temp = 8'b0; ns = UART_RXD ? counter : start; end
				counter : begin LEDG = 1'b1; ns = transmit; end
            transmit : begin  enable = 1'b1; ns = co ? RxD_ready : transmit; temp <= BaudTick ? {UART_RXD, temp[7:1]} : temp; end
            RxD_ready : begin ns = idle; LEDG = 1'b1; end
        endcase
    end

	 assign LEDR[7:0] = temp;
	 
    always @(posedge CLOCK_50) begin
        if(SW) ps <= idle;
        else ps <= ns;
    end

    always @(posedge CLOCK_50) begin
        if(SW | co) count <= 4'b0;
        else if(BaudTick) count <= count + 1'b1;
    end
    assign co = (count == 4'd8) ? 1'b1 : 1'b0;

endmodule
