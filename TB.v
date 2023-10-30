module TB();
	reg CLOCK_50 = 1'b1, rst, data_ready = 1'b0;
	reg [7:0] inp;
	wire [7:0] outp;

	reg [16 - 1 : 0] Input_mem [1000 - 1 : 0];

	Top tp(CLOCK_50, rst, data_ready, inp, outp);

	always #5 CLOCK_50 = ~CLOCK_50;

	initial begin  
		$readmemb("inputs.txt", Input_mem);
	end

	integer i;
	initial begin
		rst = 1'b1; #10
		rst = 1'b0;
		for(i = 0; i < 1000 - 1; i = i + 1)begin
			inp <= Input_mem[i]; data_ready = 1'b1; 
			#11 data_ready = 1'b0; #5000;
		end
		#5000;
		$stop;
	end
endmodule
