module Coeff_ROM #(parameter DEPTH, parameter WIDTH) (addr, Coeff_out);
  input [$clog2(DEPTH) - 1 : 0] addr;
  output reg [WIDTH - 1 : 0] Coeff_out;
  
  reg [WIDTH - 1 : 0] ROM [DEPTH - 1 : 0];
  
  initial begin
    $readmemb("coeffs.txt", ROM);
  end
  
  assign Coeff_out = ROM[addr];
endmodule