module FIR #(parameter DEPTH = 100, parameter WIDTH_IN = 16, parameter WIDTH_OUT = 38) (clk, rst, FIR_input, input_valid, addr, FIR_output, output_valid, Coef);
  input clk, rst, input_valid;
  output output_valid;
  input [WIDTH_IN - 1 : 0] Coef;
  input [WIDTH_IN - 1 : 0] FIR_input;
  output [WIDTH_OUT - 1 : 0] FIR_output;
  output [5 : 0] addr;
  
  wire cnt_en, cnt_clr, reg_ld, reg_clr, write_en, Co;
  
  DataPath #(DEPTH, WIDTH_IN, WIDTH_OUT) DP(clk, rst, cnt_en, cnt_clr, reg_ld, reg_clr, write_en, FIR_input, FIR_output, Co, addr, Coef);
  Controller CU(clk, rst, input_valid, Co, reg_ld, reg_clr, cnt_clr, cnt_en, write_en, output_valid);
endmodule
