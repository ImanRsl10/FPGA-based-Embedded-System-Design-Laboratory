module Adder #(parameter WIDTH_A, parameter WIDTH_B, parameter OUTPUT_WIDTH) (a, b, sum);
  input signed [WIDTH_A - 1 : 0] a;
  input signed [WIDTH_B - 1 : 0] b;
  output signed [OUTPUT_WIDTH - 1 : 0] sum;

  assign sum = a + b;

endmodule