`timescale 1ns / 1ps

// Top-level module for 5-stage pipelined RISC-V processor with data hazard control
module rvhazard(input logic clk, reset);

    // ----------------------------
    // Pipeline control signals
    // ----------------------------
    logic ZeroE, StallF, StallD;        // Zero flag from ALU, stall signals for IF & ID stages
    logic PCSrcE;                       // PC select: branch/jump taken
    logic RegWriteM;                    // Write enable for MEM stage
    logic MemWriteM;                    // Memory write enable for MEM stage
    logic FlushE;                       // Flush signal for EX stage
    
    // ----------------------------
    // Forwarding unit signals
    // ----------------------------
    logic [1:0] ForwardAE, ForwardBE;  // Forwarding control signals for EX stage operands
    logic [1:0] ResultSrcM;            // Select output from MEM stage
    
    // ----------------------------
    // Control signals for branches and jumps
    // ----------------------------
    logic JumpD, BranchD, JumpE, BranchE;
    logic [1:0] ResultSrcD, ResultSrcE, ResultSrcW; // Result select for various stages
    
    // ----------------------------
    // Data path control signals
    // ----------------------------
    logic MemWriteD, RegWriteE, RegWriteW, MemWriteE, ALUSrcE, RegWriteD, ALUSrcD;
    logic [1:0] ImmSrcD;          
    logic [2:0] ALUControlD, ALUControlE;
    
    // ----------------------------
    // Operand and ALU signals
    // ----------------------------
    logic [31:0] SrcBE, SrcB, SrcAE;           // Inputs to ALU after mux/forwarding
    logic [31:0] ALUResultM, ALUResultW, ALUResultE; // ALU results at different stages
    logic [31:0] ReadDataW, ReadDataM, WriteDataE;   // Memory read/write data
    logic [31:0] PCTargetE;                     // Branch target PC
    logic [31:0] PCNext;                        // Next PC value
    logic [31:0] ResultW, RD1D, RD2D;          // Forwarded and register read values
    logic [31:0] InstrD, InstrF, PCD, PCE, PCF, PCPlus4D, PCPlus4M, PCPlus4W, PCPlus4E, PCPlus4F;
    logic [31:0] RD1E, RD2E, RD2M;
    
    // ----------------------------
    // Register addresses
    // ----------------------------
    logic [4:0] rs1E, rs2E, Rs1D, Rs2D, rdE, rdM, rdW;
    
    // ----------------------------
    // Immediate extension
    // ----------------------------
    logic [31:0] ImmExtendE, ImmExtendD;

    // ----------------------------
    // PC source logic
    // ----------------------------
    assign PCSrcE = (BranchE & ZeroE) | JumpE; // Branch/jump decision

    // ----------------------------
    // Instantiate Forwarding Unit
    // ----------------------------
    forwarding_unit forwarding_unit(
        .Rs2E(rs2E),
        .Rs1E(rs1E),
        .RdM(rdM),
        .RdW(rdW),
        .RegWriteM(RegWriteM),
        .RegWriteW(RegWriteW),
        .ForwardAE(ForwardAE),
        .ForwardBE(ForwardBE)
    );

    // ----------------------------
    // PC calculation units
    // ----------------------------
    Adder PC_Plus_4(.A(PCF), .B(32'd4), .Sum(PCPlus4F));       // PC+4 for next sequential instruction
    Adder PC_Target(.A(PCE), .B(ImmExtendE), .Sum(PCTargetE)); // Branch target calculation

    // ----------------------------
    // Mux for next PC
    // ----------------------------
    mux2 PC_Next(.d0(PCPlus4F), .d1(PCTargetE), .s(PCSrcE), .y(PCNext));

    // ----------------------------
    // Program Counter
    // ----------------------------
    program_counter ProgramCounter(
        .clk(clk),
        .reset(reset),
        .en(StallF),
        .PCNext(PCNext),
        .PC(PCF)
    );

    // ----------------------------
    // Instruction memory fetch
    // ----------------------------
    instr_mem instruction_memory(
        .A(PCF),
        .RD(InstrF)
    );

    // ----------------------------
    // IF/ID Pipeline register
    // ----------------------------
    IF_ID IF_ID(
        .clk(clk),
        .reset(reset),
        .en(StallD),
        .InstrF(InstrF),
        .PCF(PCF),
        .PCPlus4F(PCPlus4F),
        .InstrD(InstrD),
        .PCD(PCD),
        .PCPlus4D(PCPlus4D)
    );

    // ----------------------------
    // Register file read
    // ----------------------------
    register_file register_file(
        .clk(clk),
        .A1(InstrD[19:15]),
        .A2(InstrD[24:20]),
        .A3(rdW),
        .wd3(ResultW),
        .we(RegWriteW),
        .rd1(RD1D),
        .rd2(RD2D)
    );

    // ----------------------------
    // Immediate extension unit
    // ----------------------------
    ExtendUnit Extend(
        .Instr(InstrD),
        .ImmSrc(ImmSrcD),
        .ImmExtend(ImmExtendD)
    );

    // ----------------------------
    // Control unit for ID stage
    // ----------------------------
    control_unit control_unit(
        .op(InstrD[6:0]),
        .funct3(InstrD[14:12]),
        .funct7b5(InstrD[30]),
        .Branch(BranchD),
        .Jump(JumpD),
        .ResultSrc(ResultSrcD),
        .MemWrite(MemWriteD),
        .ImmSrc(ImmSrcD),
        .RegWrite(RegWriteD),
        .ALUSrc(ALUSrcD),
        .ALUControl(ALUControlD)
    );

    // ----------------------------
    // Hazard detection unit
    // ----------------------------
    HazardUnit hazard_unit(
        .Rs1D(InstrD[19:15]),
        .Rs2D(InstrD[24:20]),
        .RdE(rdE),
        .ResultSrcE0(ResultSrcE[0]),
        .StallF(StallF),
        .StallD(StallD),
        .FlushE(FlushE)
    );

    // ----------------------------
    // ID/EX Pipeline register
    // ----------------------------
    ID_IE ID_IE(
        .clk(clk),
        .reset(reset),
        .flush(FlushE),
        .rd1D(RD1D),
        .rd2D(RD2D),
        .PCD(PCD),
        .rs1D(InstrD[19:15]),
        .rs2D(InstrD[24:20]),
        .rdD(InstrD[11:7]),
        .ImmExtendD(ImmExtendD),
        .PCPlus4D(PCPlus4D),
        .RegWriteD(RegWriteD),
        .ResultSrcD(ResultSrcD),
        .MemWriteD(MemWriteD),
        .JumpD(JumpD),
        .BranchD(BranchD),
        .ALUSrcD(ALUSrcD),
        .ALUControlD(ALUControlD),
        .rd1E(RD1E),
        .rd2E(RD2E),
        .PCE(PCE),
        .rs1E(rs1E),
        .rs2E(rs2E),
        .rdE(rdE),
        .ImmExtendE(ImmExtendE),
        .PCPlus4E(PCPlus4E),
        .RegWriteE(RegWriteE),
        .ResultSrcE(ResultSrcE),
        .MemWriteE(MemWriteE),
        .JumpE(JumpE),
        .BranchE(BranchE),
        .ALUSrcE(ALUSrcE),
        .ALUControlE(ALUControlE)
    );

    // ----------------------------
    // ALU operand selection
    // ----------------------------
    mux2 Src_B(.d0(SrcB), .d1(ImmExtendE), .s(ALUSrcE), .y(SrcBE));
    mux3to1 mux(.d0(RD1E), .d1(ResultW), .d2(ALUResultM), .s(ForwardAE), .y(SrcAE));
    mux3to1 mux2(.d0(RD2E), .d1(ResultW), .d2(ALUResultM), .s(ForwardBE), .y(SrcB));

    // ----------------------------
    // ALU execution
    // ----------------------------
    ALU ALU(
        .SrcA(SrcAE),
        .SrcB(SrcBE),
        .ALUControl(ALUControlE),
        .ALUResult(ALUResultE),
        .Zero(ZeroE)
    );

    // ----------------------------
    // EX/MEM Pipeline register
    // ----------------------------
    IE_IM IE_IM(
        .clk(clk),
        .reset(reset),
        .ALUResultE(ALUResultE),
        .RD2E(RD2E),
        .RegWriteM(RegWriteM),
        .MemWriteM(MemWriteM),
        .ResultSrcM(ResultSrcM),
        .RegWriteE(RegWriteE),
        .MemWriteE(MemWriteE),
        .ResultSrcE(ResultSrcE),
        .rdE(rdE),
        .PCPlus4E(PCPlus4E),
        .ALUResultM(ALUResultM),
        .RD2M(RD2M),
        .rdM(rdM),
        .PCPlus4M(PCPlus4M)
    );

    // ----------------------------
    // Data Memory
    // ----------------------------
    data_mem data_memory(
        .clk(clk),
        .we(MemWriteM),
        .A(ALUResultM),
        .WD(RD2M),
        .ReadData(ReadDataM)
    );

    // ----------------------------
    // MEM/WB Pipeline register
    // ----------------------------
    IM_IW IM_IW(
        .clk(clk),
        .reset(reset),
        .ALUResultM(ALUResultM),
        .ReadDataM(ReadDataM),
        .PCPlus4M(PCPlus4M),
        .RegWriteM(RegWriteM),
        .ResultSrcM(ResultSrcM),
        .rdM(rdM),
        .ALUResultW(ALUResultW),
        .ReadDataW(ReadDataW),
        .PCPlus4W(PCPlus4W),
        .rdW(rdW),
        .RegWriteW(RegWriteW),
        .ResultSrcW(ResultSrcW)
    );

    // ----------------------------
    // Result selection for write-back
    // ----------------------------
    mux3to1 result(
        .d0(ALUResultW),
        .d1(ReadDataW),
        .d2(PCPlus4W),
        .s(ResultSrcW),
        .y(ResultW)
    );

endmodule
