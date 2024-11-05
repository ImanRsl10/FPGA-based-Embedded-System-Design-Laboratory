module TB();
	reg CLOCK_50 = 1'b1, rst;
	reg inp;
	wire outp;

	reg [16 - 1 : 0] Input_mem [1000 - 1 : 0];

	Top tp(CLOCK_50, rst, inp, outp);

	always #5 CLOCK_50 = ~CLOCK_50;

	initial begin  
		$readmemb("inputs.txt", Input_mem);
	end

	//integer i;
	initial begin
		rst = 1'b1; #10
		rst = 1'b0;
		#10 inp = 1'b0; #29 inp = 1'b1;
		repeat(4) begin
            		#4400 inp = 1'b0;
	    		#4400 inp = 1'b1;
        	end
		//for(i = 0; i < 10; i = i + 1)begin
			//inp <= Input_mem[i]; #35200; data_ready = 1'b1; 
			//#11 data_ready = 1'b0;
		//end
		#35000;
		$stop;
	end
endmodule
