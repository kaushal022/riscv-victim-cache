`timescale 1ns / 1ps
// RV32I 5-Stage Pipelined Processor
// Baseline Implementation

module rv32i_top (
    input  wire        clk,
    input  wire        rst,
    output wire [31:0] alu_out,
    output wire [31:0] pc_out
);

    // Internal wires 
    
    // PC
    wire [31:0] pc, next_pc;
    assign pc_out = pc;

    // IF/ID
    wire [31:0] instr;
    wire [6:0]  ifid_opcode;
    wire [4:0]  ifid_rs1, ifid_rs2, ifid_rd;
    wire [2:0]  ifid_func3;
    wire [6:0]  ifid_func7;
    wire [31:0] ifid_pc;

    // Hazard & Cache Stalls
    wire        stall, if_id_flush, id_ex_flush;
    wire        cache_stall = 1'b0;
    wire        global_stall = cache_stall;

    // Memory
    wire [31:0] dmem_data_out;

    // Registers
    wire [31:0] rf_out_1, rf_out_2;

    // ID/EX
    wire [6:0]  idex_opcode;
    wire [31:0] idex_reg_out_1, idex_reg_out_2;
    wire [4:0]  idex_rs1, idex_rs2, idex_rd;
    wire [2:0]  idex_func3;
    wire [6:0]  idex_func7;
    wire [31:0] idex_imm;
    wire [31:0] idex_pc;
    wire [1:0]  idex_pc_sel;
    wire        idex_jump, idex_branch, idex_mem_re, idex_mem_we, idex_mem_to_reg, idex_reg_we;
    wire [1:0]  idex_alu_op;
    wire [1:0]  idex_op_a_sel;
    wire        idex_op_b_sel;

    // EX/MEM
    wire [31:0] alu_result;
    wire        branch_taken;
    wire [31:0] exmem_alu_result;
    wire        exmem_branch_taken;
    wire [4:0]  exmem_rs2;
    wire [31:0] exmem_reg_out_2;
    wire [4:0]  exmem_rd;
    wire        exmem_mem_re, exmem_mem_we, exmem_mem_to_reg, exmem_reg_we;
    wire        exmem_jump, exmem_branch;
    wire [2:0]  exmem_func3;
    wire [1:0]  exmem_pc_sel;
    wire [31:0] exmem_pc;     

    // MEM/WB
    wire [4:0]  memwb_rd;
    wire [31:0] memwb_alu_result;
    wire [31:0] memwb_mem_data;
    wire [31:0] memwb_pc;   
    wire        memwb_reg_we, memwb_mem_to_reg, memwb_jump;

    // Forwarding
    wire [1:0]  forward_a, forward_b;
    wire [31:0] alu_in_1, alu_in_2_fw, alu_in_2;

    
    //  IF Stage
    pc_register PC_REG (
        .clk(clk), .rst(rst),
        .stall(stall | global_stall),
        .next_pc(next_pc),
        .pc(pc)
    );

    instr_mem IMEM (
        .addr(pc),
        .instr(instr)
    );

    
    //  IF/ID Pipeline Register
    if_id_reg IF_ID (
        .clk(clk), .rst(rst),
        .stall(stall | global_stall), .flush(if_id_flush & !global_stall),
        .instr_in(instr), .pc_in(pc),
        .opcode(ifid_opcode), .rs1(ifid_rs1), .rs2(ifid_rs2),
        .rd(ifid_rd), .func3(ifid_func3), .func7(ifid_func7),
        .pc_out(ifid_pc)
    );

    
    //  ID Stage
    wire [31:0] wb_data = memwb_jump       ? (memwb_pc + 32'd4) :
                          memwb_mem_to_reg  ? memwb_mem_data :
                                             memwb_alu_result;

    reg_file RF (
        .clk(clk), .rst(rst),
        .we(memwb_reg_we),
        .rs1(ifid_rs1), .rs2(ifid_rs2), .rd(memwb_rd),
        .data_in(wb_data),
        .reg_out_1(rf_out_1), .reg_out_2(rf_out_2)
    );

    wire [31:0] imm_out;
    imm_gen IMM_GEN (
        .instr({ifid_func7, ifid_rs2, ifid_rs1, ifid_func3, ifid_rd, ifid_opcode}),
        .imm(imm_out)
    );

    wire id_branch, id_mem_re, id_mem_to_reg, id_mem_we, id_reg_we, id_jump;
    wire [1:0] id_pc_sel, id_alu_op, id_op_a_sel;
    wire id_op_b_sel;
    
    control_unit CU (
        .opcode(ifid_opcode),
        .stall(stall | global_stall),
        .reg_we(id_reg_we), .mem_we(id_mem_we), .mem_re(id_mem_re),
        .mem_to_reg(id_mem_to_reg), .alu_op(id_alu_op), .op_a_sel(id_op_a_sel),
        .op_b_sel(id_op_b_sel), .pc_sel(id_pc_sel), .jump(id_jump), .branch(id_branch)
    );

    
    //  ID/EX Pipeline Register
    id_ex_reg ID_EX (
        .clk(clk), .rst(rst), .stall(global_stall), .flush(id_ex_flush & !global_stall),
        .opcode_in(ifid_opcode),    .opcode_out(idex_opcode),
        .reg_out_1_in(rf_out_1),    .reg_out_1(idex_reg_out_1),
        .reg_out_2_in(rf_out_2),    .reg_out_2(idex_reg_out_2),
        .rs1_in(ifid_rs1),          .rs1_out(idex_rs1),
        .rs2_in(ifid_rs2),          .rs2_out(idex_rs2),
        .rd_in(ifid_rd),            .rd_out(idex_rd),
        .func3_in(ifid_func3),      .func3_out(idex_func3),
        .func7_in(ifid_func7),      .func7_out(idex_func7),
        .imm_in(imm_out),           .imm_out(idex_imm),
        .pc_in(ifid_pc),            .pc_out(idex_pc),
        .reg_we_in(id_reg_we),      .reg_we_out(idex_reg_we),
        .mem_we_in(id_mem_we),      .mem_we_out(idex_mem_we),
        .mem_re_in(id_mem_re),      .mem_re_out(idex_mem_re),
        .mem_to_reg_in(id_mem_to_reg),.mem_to_reg_out(idex_mem_to_reg),
        .alu_op_in(id_alu_op),      .alu_op_out(idex_alu_op),
        .op_a_sel_in(id_op_a_sel),  .op_a_sel_out(idex_op_a_sel),
        .op_b_sel_in(id_op_b_sel),  .op_b_sel_out(idex_op_b_sel),
        .pc_sel_in(id_pc_sel),      .pc_sel_out(idex_pc_sel),
        .jump_in(id_jump),          .jump_out(idex_jump),
        .branch_in(id_branch),      .branch_out(idex_branch)
    );

    
    //  EX Stage
    wire [3:0] alu_ctrl;
    alu_control ALU_CTRL (
        .alu_op(idex_alu_op),
        .func3(idex_func3),
        .func7(idex_func7),
        .alu_ctrl(alu_ctrl)
    );

    // Forwarded rs1 value (before op_a_sel mux)
    wire [31:0] rs1_forwarded = (forward_a == 2'b01) ? exmem_alu_result :
                                (forward_a == 2'b10) ? wb_data : idex_reg_out_1;

    // ALU operand A: select between rs1, PC, or 0 (LUI)
    assign alu_in_1 = (idex_op_a_sel == 2'b01) ? idex_pc :
                      (idex_op_a_sel == 2'b10) ? 32'd0 :
                                                 rs1_forwarded;

    assign alu_in_2_fw = (forward_b == 2'b01) ? exmem_alu_result :
                         (forward_b == 2'b10) ? wb_data : idex_reg_out_2;

    assign alu_in_2 = idex_op_b_sel ? idex_imm : alu_in_2_fw;

    alu ALU (
        .op_a(alu_in_1), .op_b(alu_in_2), .alu_instr(alu_ctrl),
        .is_branch(idex_branch),  // *** FIX: connect is_branch ***
        .result(alu_result), .branch_taken(branch_taken),
        .func3(idex_func3)
    );
    assign alu_out = alu_result;

    
    //  EX/MEM Pipeline Register
    ex_mem_reg EX_MEM (
        .clk(clk), .rst(rst), .stall(global_stall),
        .alu_result_in(alu_result),      .alu_result_out(exmem_alu_result),
        .branch_taken_in(branch_taken),  .branch_taken_out(exmem_branch_taken),
        .rs2_in(idex_rs2),               .rs2_out(exmem_rs2),
        .reg_out_2_in(alu_in_2_fw),      .reg_out_2(exmem_reg_out_2),
        .rd_in(idex_rd),                 .rd_out(exmem_rd),
        .pc_in(idex_pc),                 .pc_out(exmem_pc),  // *** FIX: connect PC ***
        .imm_in(idex_imm),               .imm_out(),
        .mem_re_in(idex_mem_re),         .mem_re_out(exmem_mem_re),
        .mem_we_in(idex_mem_we),         .mem_we_out(exmem_mem_we),
        .reg_we_in(idex_reg_we),         .reg_we_out(exmem_reg_we),
        .mem_to_reg_in(idex_mem_to_reg), .mem_to_reg_out(exmem_mem_to_reg),
        .jump_in(idex_jump),             .jump_out(exmem_jump),
        .branch_in(idex_branch),         .branch_out(exmem_branch),
        .func3_in(idex_func3),           .func3_out(exmem_func3),
        .pc_sel_in(idex_pc_sel),         .pc_sel_out(exmem_pc_sel)
    );

    
    //  MEM Stage - Baseline Memory
    data_mem DMEM (
        .clk(clk), .rst(rst),
        .byte_en(exmem_func3),
        .mem_we(exmem_mem_we),
        .mem_re(exmem_mem_re),
        .addr(exmem_alu_result),
        .data_in(exmem_reg_out_2),
        .data_out(dmem_data_out)
    );

    
    //  MEM/WB Pipeline Register
    mem_wb_reg MEM_WB (
        .clk(clk), .rst(rst), .stall(global_stall),
        .rd_in(exmem_rd),               .rd_out(memwb_rd),
        .alu_result_in(exmem_alu_result),.alu_result_out(memwb_alu_result),
        .mem_data_in(dmem_data_out),     .mem_data_out(memwb_mem_data),
        .pc_in(exmem_pc),               .pc_out(memwb_pc),  // *** FIX: connect PC ***
        .reg_we_in(exmem_reg_we),        .reg_we_out(memwb_reg_we),
        .mem_to_reg_in(exmem_mem_to_reg),.mem_to_reg_out(memwb_mem_to_reg),
        .jump_in(exmem_jump),            .jump_out(memwb_jump)
    );

    
    //  Hazard & Forwarding Units
    forwarding_unit FWD_UNIT (
        .id_ex_rs1(idex_rs1), .id_ex_rs2(idex_rs2),
        .ex_mem_rd(exmem_rd), .ex_mem_reg_we(exmem_reg_we),
        .mem_wb_rd(memwb_rd), .mem_wb_reg_we(memwb_reg_we),
        .forward_a(forward_a), .forward_b(forward_b)
    );

    hazard_unit HZD_UNIT (
        .if_id_rs1(ifid_rs1), .if_id_rs2(ifid_rs2), .if_id_opcode(ifid_opcode),
        .id_ex_rd(idex_rd), .id_ex_mem_re(idex_mem_re),
        .id_ex_branch(idex_branch), .id_ex_jump(idex_jump), .id_ex_pc_sel(idex_pc_sel),
        .branch_taken(branch_taken),
        .stall(stall), .if_id_flush(if_id_flush), .id_ex_flush(id_ex_flush)
    );
    
    //  Next PC Logic
    reg [31:0] next_pc_r;
    assign next_pc = next_pc_r;

    always @(*) begin
        next_pc_r = pc + 32'd4;               

        if ((stall || global_stall) && !(idex_pc_sel == 2'b01 ||
                       idex_pc_sel == 2'b10 ||
                       (idex_branch && branch_taken)))
            next_pc_r = pc;                   

        else if (idex_pc_sel == 2'b01)
            next_pc_r = idex_pc + idex_imm;
        else if (idex_pc_sel == 2'b10)
            next_pc_r = {(rs1_forwarded + idex_imm) >> 1, 1'b0};

        // Branch taken: PC + imm
        else if (idex_branch && branch_taken)
            next_pc_r = idex_pc + idex_imm;
    end

endmodule
