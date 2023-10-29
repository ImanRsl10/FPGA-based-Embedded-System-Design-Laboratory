module BaudTickGen(
    input clk, rst, enable,
    output tick  // generate a tick at the specified baud rate * oversampling
);
    parameter ClkFrequency = 50000000;
    parameter Baud = 115200;
    parameter Oversampling = 1;

    reg [10:0] count;
    
    always @(posedge clk) begin
        if(rst | tick) count <= 11'b0;
        else count <= count + 1'b1;
    end

    assign tick = (count == ((ClkFrequency/Baud)/Oversampling)) ? 1'b1 : 1'b0;
//enable | tick
endmodule