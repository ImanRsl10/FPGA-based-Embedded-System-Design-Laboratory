module Top(clk, rst, flush, Instruction, Result_WB, PC_In, writeBackEn, Dest_wb, hazard, SR, WB_EN, MEM_R_EN, MEM_W_EN, B, S, EXE_CMD, PC, Val_Rn, Val_Rm, imm, Shift_operand,
	Signed_imm_24, Dest);

	input clk, rst, flush;
	input[31:0] Instruction;
        input[31:0] Result_WB;
	input[31:0] PC_In;
        input writeBackEn;
        input[3:0] Dest_wb;
        input hazard;
        input[3:0] SR;

	output WB_EN, MEM_R_EN, MEM_W_EN;
	output B,S;
	output [3:0] EXE_CMD;
	output [31:0] PC;
	output [31:0] Val_Rn, Val_Rm;
	output imm;
	output [11:0] Shift_operand;
	output [23:0] Signed_imm_24;
	output [3:0] Dest;

	wire WB_EN_out, MEM_R_EN_out, MEM_W_EN_out, B_out, S_out;
	wire[3:0] EXE_CMD_out;
        wire[31:0] Val_Rn_out, Val_Rm_out;
        wire imm_out;
        wire[11:0] Shift_operand_out;
        wire[23:0] Signed_imm_24_out;
        wire[3:0] Dest_out;
        wire[3:0] src1_out, src2_out;
        wire Two_src_out;

	ID_Stage ID(clk, rst, Instruction, Result_WB, writeBackEn, Dest_wb, hazard, SR, WB_EN_out, MEM_R_EN_out, MEM_W_EN_out, B_out, S_out, EXE_CMD_out,
	Val_Rn_out, Val_Rm_out, imm_out, Shift_operand_out, Signed_imm_24_out, Dest_out, src1_out, src2_out, Two_src_out);

	ID_Stage_Reg IDreg(clk, rst, flush, WB_EN_out, MEM_R_EN_out, MEM_W_EN_out, B_out, S_out, EXE_CMD_out, PC_In, Val_Rn_out, Val_Rm_out, imm_out, Shift_operand_out,
	Signed_imm_24_out, Dest_out, WB_EN, MEM_R_EN, MEM_W_EN, B, S, EXE_CMD, PC, Val_Rn, Val_Rm, imm, Shift_operand, Signed_imm_24, Dest);

endmodule
