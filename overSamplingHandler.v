module overSamplingHandler(clk, rst, RxD_raw, BaudTick, RxD, co, count);
    input clk, rst, RxD_raw, BaudTick;
    output RxD, co;
    reg ns, ps;
    parameter idle = 0, shift = 1;
    output reg [2:0] count;
    reg clr, cnt_clr, sh_en, cnt_en;
    // reg [2:0] count;
    reg [3:0] temp;
    always@(ps, co)begin
        case(ps)
            idle: ns <= shift;
            shift: ns <= co ? idle : shift;
        endcase
    end
    always@(ps)begin
        {clr, cnt_clr, sh_en, cnt_en} = 4'b000;
        case(ps)
            idle: {clr, cnt_clr} = 2'b11;
            shift: {sh_en, cnt_en} = 2'b11; 
        endcase

    end
    always@(posedge clk)begin
        if(rst)
            ps <= idle;
        else
            ps <= ns; 
    end

    always@(posedge clk)begin
        if(rst)
            temp <= 4'b0000;
        else if (sh_en & BaudTick)
            temp <= {RxD_raw, temp[3:1]};


    end

    always @(posedge clk) begin
        if(rst | cnt_clr)
            count <= 3'b00;
        else if(cnt_en & BaudTick)
            count <= count + 1'b1;

    end 

    assign co = (count == 3'b100);
    assign RxD = temp[2];
endmodule