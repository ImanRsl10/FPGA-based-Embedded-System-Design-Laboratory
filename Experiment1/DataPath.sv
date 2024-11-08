module DataPath #(parameter DEPTH, parameter WIDTH_IN, parameter WIDTH_OUT) (clk, rst, cnt_en, cnt_clr, reg_ld, reg_clr, write_en, FIR_input, FIR_output, Co, addr, Coef);
  input clk, rst, cnt_en, cnt_clr, reg_ld, reg_clr, write_en;
  input [WIDTH_IN - 1 : 0] FIR_input;
  output [WIDTH_OUT - 1 : 0] FIR_output;
  output Co;
  input [WIDTH_IN - 1 : 0] Coef;
  output [$clog2(DEPTH) - 1 : 0] addr;
  reg signed [WIDTH_IN - 1 : 0] mem_out;//, Coeff_out;
  reg signed [2 * WIDTH_IN - 1 : 0] mult_out;
  reg signed [WIDTH_OUT - 1 : 0] Adder_out;
	wire [$clog2(DEPTH) - 1 : 0] address;
	assign address = addr;
  //Counter
  Counter #(DEPTH) counter(clk, rst, cnt_clr, cnt_en, addr, Co);
  //Coeff ROM
  //Coeff_ROM #(DEPTH, WIDTH_IN) Coeffs(addr, Coeff_out);
  //Input Mem
  Input_Mem #(DEPTH, WIDTH_IN) Inp_mem(clk, rst, write_en, address, FIR_input, mem_out);
  //Multiplier
  Multiplier #(WIDTH_IN) Mult(Coef, mem_out, mult_out);
  //Adder
  Adder #(2 * WIDTH_IN, WIDTH_OUT, WIDTH_OUT) Add(mult_out, FIR_output, Adder_out);
  //Register
  Register #(WIDTH_OUT) Reg(clk, rst, reg_clr, reg_ld, Adder_out, FIR_output);
endmodule