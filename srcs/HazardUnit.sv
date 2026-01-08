`timescale 1ns / 1ps

// ----------------------------
// Hazard detection unit for load-use data hazards
// ----------------------------
module HazardUnit(
    input  logic [4:0] Rs1D,     // Source register 1 in ID stage
    input  logic [4:0] Rs2D,     // Source register 2 in ID stage
    input  logic [4:0] RdE,      // Destination register in EX stage
    input  logic       ResultSrcE0, // 1 if EX stage instruction is a load (lw)
    output logic StallF,          // Stall signal for IF stage
    output logic StallD,          // Stall signal for ID stage
    output logic FlushE           // Flush signal for EX stage
);

    // ----------------------------
    // Load-use hazard detection
    // ----------------------------
    // Condition for stalling:
    // - Current instruction in EX stage is a load (ResultSrcE0==1)
    // - Any source register in ID stage matches destination register in EX stage
    // - Destination register is not x0 (register zero)
    logic lwStall;
    assign lwStall = ResultSrcE0 && ((Rs1D == RdE) || (Rs2D == RdE)) && (RdE != 0);

    // ----------------------------
    // Control signals based on hazard
    // ----------------------------
    assign FlushE = lwStall;      // Flush EX stage if load-use hazard
    assign StallF = ~FlushE;      // Stall IF stage while EX is flushed
    assign StallD = ~FlushE;      // Stall ID stage while EX is flushed

endmodule
