module Controller (clk, rst, input_valid, Co, reg_ld, reg_clr, cnt_clr, cnt_en, write_en, output_valid);
  input clk, rst, input_valid, Co;
  output reg reg_ld, reg_clr, cnt_clr, cnt_en, write_en, output_valid;
  
  reg [1:0] ps, ns;
  parameter Idle = 0, Clear = 1, Calc = 2, Done = 3;
  
  always @(ps, input_valid, Co)begin
    ns = Idle;
    case(ps)
	  Idle: ns <= (input_valid) ? Clear : Idle;
	  Clear: ns <= Calc;
	  Calc: ns <=  Done;
	  Done: ns <= Idle;
	endcase
  end
  
  always @(ps)begin
    {reg_ld, reg_clr, cnt_clr, cnt_en, write_en, output_valid} = 6'b000000;
    case(ps)
	  Clear: {reg_clr, cnt_clr, write_en} = 3'b111;
	  Calc: {cnt_en, reg_ld} = 2'b11;
	  Done: output_valid = 1'b1;
    endcase
  end
  
  always @(posedge clk, posedge rst)begin
    if(rst)
	  ps <= Idle;
	else
	  ps <= ns;
  end
endmodule