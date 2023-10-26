module async_reciever_TB();
    reg clk = 1'b0, rst = 1'b1, RxD = 1'b1;
    wire RxD_data_ready;
    wire [7:0] RxD_data;

    async_receiver #(50000000, 115200, 4) received(clk, rst, RxD, RxD_data_ready, RxD_data);

    always #20 clk = ~clk;

    initial begin
        #23 rst = 1'b0;
        #10 RxD = 1'b0;
        #29 RxD = 1'b1;
        repeat(8) begin
            #104000; RxD = 1'b1;// $random()%2;
        end
        #104000;
	#10 RxD = 1'b0;
        #29 RxD = 1'b1;
        repeat(4) begin
            #104000 RxD = 1'b1;// $random()%2;
	    #104000 RxD = 1'b0;
        end
	$stop;
    end

endmodule
