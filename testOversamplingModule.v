module testOversamplingModule();
    reg clk, rst, RxD_raw;
    reg enable; 
    parameter ClkFrequency = 50000000;
    parameter Baud = 115200;
    parameter Oversampling = 4;	// needs to be a power of 2

    wire RxD_data_ready;
    wire [7:0] RxD_data;
    //50 MegaHertz clock
    always #10 clk = ~clk;
    initial begin 
        clk = 1'b1;
    end

    //reset the system
    initial begin 
        rst = 1'b1;
        #28 begin rst = 1'b0;
        end
    end 
    async_receiver #(50000000, 115200, 1) received(.clk(clk), .rst(rst), .RxD_in(RxD_raw), .RxD_data_ready(RxD_data_ready), .RxD_data(RxD_data));
    initial begin
    RxD_raw = 1'b0; #35000; 
	//=====================//
	RxD_raw = 1'b0; #35000;
	RxD_raw = 1'b1; #35000;
	RxD_raw = 1'b1; #35000;
	RxD_raw = 1'b0; #35000;
	//========4===========//
	RxD_raw = 1'b1; #35000;
	RxD_raw = 1'b0; #35000;
	RxD_raw = 1'b1; #35000;
	RxD_raw = 1'b0; #35000;
    //========2nd Test ===//
    RxD_raw = 1'b0; #35000;
	//=====================//
	RxD_raw = 1'b0; #35000;
	RxD_raw = 1'b1; #35000;
	RxD_raw = 1'b1; #35000;
	RxD_raw = 1'b1; #35000;
	//========4===========//
	RxD_raw = 1'b0; #35000;
	RxD_raw = 1'b0; #35000;
	RxD_raw = 1'b0; #35000;
	RxD_raw = 1'b1; #35000;
    $stop;
    end 


endmodule