module overSamplingHandlerTB();

    reg clk, rst, RxD_raw;
    wire RxD;
    overSamplingHandler uut(clk, rst, RxD_raw, RxD);
    initial begin
        clk = 1'b0;
        rst = 1'b1;
    end
    always #5 clk = ~clk ; 
    initial begin
        #6 rst = 1'b0;
        #6 RxD_raw = 1'b1;
        // #44 RxD_raw = 1'b1;
        #44 RxD_raw =  1'b0;
        #66 RxD_raw =  1'b1;
        #220 $stop;
    end 




endmodule