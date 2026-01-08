`timescale 1ns / 1ps

// ----------------------------
// Forwarding Unit
// Resolves data hazards by forwarding ALU/MEM results to EX stage operands
// ----------------------------
module forwarding_unit(
    input logic [4:0] Rs2E, Rs1E,   // Source registers in EX stage
    input logic [4:0] RdM, RdW,     // Destination registers in MEM and WB stages
    input logic RegWriteM, RegWriteW, // RegWrite signals for MEM and WB stages
    output logic [1:0] ForwardAE, ForwardBE // Forwarding control signals for EX stage operands
);

    always_comb begin
        // ----------------------------
        // Forwarding for EX stage operand A
        // ----------------------------
        // Case 1: Match with MEM stage destination (highest priority)
        if ((Rs1E == RdM) && (RegWriteM) && (Rs1E != 0)) begin
            ForwardAE = 2'b10; // Forward from MEM stage
        end
        // Case 2: Match with WB stage destination
        else if ((Rs1E == RdW) && (RegWriteW) && (Rs1E != 0)) begin
            ForwardAE = 2'b01; // Forward from WB stage
        end
        // Case 3: No forwarding needed
        else begin
            ForwardAE = 2'b00; // Use value from register file
        end

        // ----------------------------
        // Forwarding for EX stage operand B
        // ----------------------------
        if ((Rs2E == RdM) && (RegWriteM) && (Rs2E != 0)) begin
            ForwardBE = 2'b10; // Forward from MEM stage
        end
        else if ((Rs2E == RdW) && (RegWriteW) && (Rs2E != 0)) begin
            ForwardBE = 2'b01; // Forward from WB stage
        end
        else begin
            ForwardBE = 2'b00; // Use value from register file
        end
    end

endmodule

