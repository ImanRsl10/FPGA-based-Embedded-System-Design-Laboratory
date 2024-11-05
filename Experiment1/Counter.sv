module Counter #(parameter DEPTH)(clk, rst, clr, cnt_en, cnt, Co);
  input clk, rst, clr, cnt_en;
  output logic [$clog2(DEPTH) - 1 : 0] cnt;
  output Co;
  
  always @(posedge clk, posedge rst)begin
    if(rst)
      cnt <= 0;
    else if(clr)
      cnt <= 0;
    else if (cnt_en)
      cnt <= cnt + 1'b1;
  end

  assign Co = &cnt;
endmodule