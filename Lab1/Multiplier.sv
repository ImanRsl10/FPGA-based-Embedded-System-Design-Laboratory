module Multiplier #(parameter WIDTH) (a, b, mult_out);
  input signed [WIDTH - 1 : 0] a, b;
  output signed [2 * WIDTH - 1 : 0] mult_out;
  
  assign mult_out = a * b;
endmodule