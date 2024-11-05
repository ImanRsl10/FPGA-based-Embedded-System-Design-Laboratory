module BaudTickGen_TB();
    reg clk = 1'b1, enable = 1'b1;
    wire tick;

    BaudTickGen gen(clk, enable,tick);

    always #20 clk = ~clk;

    initial begin
        #11 enable = 1'b0;
        #520000;
        $stop;
    end
endmodule
