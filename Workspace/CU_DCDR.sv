`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Cal Poly
// Engineer: Binh To
// 
// Create Date: 11/05/2023 01:19:41 AM
// Design Name: Control Unit Module
// Module Name: CU_DCDR
// Project Name: RISC-V Otter MCU
// Target Devices: Basys3
// Description: Control Unit Decoder for the MCU. This module reads the intructions' inputs (opcodes, funct3 bits, the 30th bit of the intructions
//              signals from Branch Condition Generator Module) asynchronously. It outputs the MUX's select signals (alu_fun, alu_srcA, alu_srcB, pcSource, rf_wr_sel)
//              across the MCU. Note: in the case where intructions have the same opcodes, funct3 bits will be the determinant of what signals are outputted.
//////////////////////////////////////////////////////////////////////////////////


module CU_DCDR(
    input logic [6:0] DCDR_ir_opcode,
    input logic [2:0] DCDR_ir_funct,
    input logic DCDR_ir_30,
    input logic DCDR_int_taken,

    
    output logic DCDR_jump,
    output logic DCDR_branch,
    
    output logic FSM_regWrite,
    output logic FSM_memWE2,
    output logic FSM_memRDEN2,
    
    output logic [3:0] DCDR_alu_fun,
    output logic [1:0] DCDR_alu_scra,
    output logic [2:0] DCDR_alu_scrb,
    output logic [1:0] DCDR_rf_wr_sel
    );
    
    always_comb begin
    // Initialize all outputs to zeros
        DCDR_alu_fun = 4'b0000;
        DCDR_alu_scra = 2'b00;
        DCDR_alu_scrb = 3'b000;
        DCDR_rf_wr_sel = 2'b00;
        FSM_regWrite = 1'b0;
        FSM_memWE2 = 1'b0;
        FSM_memRDEN2 = 1'b0;  
        DCDR_jump = 1'b0;
        DCDR_branch = 1'b0; 
        
        case (DCDR_ir_opcode)
            // R-type - All have the same opcode, but different function number.
            // Determine what the ALU function is going to be. The 30th bit determines the MSB of the instructions
            // The 3 LSBs are determined by 3-bit instruction function             
            7'b0110011: begin // (add, and, or, sll, sly, slty, sra, srl, sub, xor)
                DCDR_alu_fun = {DCDR_ir_30, DCDR_ir_funct};
                DCDR_alu_scra = 2'b00;
                DCDR_alu_scrb = 3'b000;
                DCDR_rf_wr_sel = 2'b11;  
                FSM_regWrite = 1'b1;          
            end
            // I-type
            7'b0010011: begin // (addi, ori, slli, slti, sltiu, xori)
                // This if-else statement deals with srai and srli due to having the same funct. If true then alu_fuc is either srai or srli.
                // The 30th bit will determine whether it's a srai or srli
                // If false then the instruction is one of the remaining I-type instructions.
                if (DCDR_ir_funct == 3'b101) // srai and srli
                    DCDR_alu_fun = {DCDR_ir_30, DCDR_ir_funct};
                else
                    DCDR_alu_fun = {1'b0, DCDR_ir_funct};                     
                DCDR_alu_scra = 2'b00;
                DCDR_alu_scrb = 3'b001;
                DCDR_rf_wr_sel = 2'b11;
                FSM_regWrite = 1'b1;
            end 
             
            // I-type - jalr case          
            7'b1100111: begin 
                DCDR_rf_wr_sel = 2'b00;
                FSM_regWrite = 1'b1;
                DCDR_jump = 1'b1;
            end 
                               
            // I-type - load case
            7'b0000011: begin // (lb, lbu, lh, lhu, lw)
                DCDR_alu_fun = 4'b0000;
                DCDR_alu_scra = 2'b00;
                DCDR_alu_scrb = 3'b001;
                DCDR_rf_wr_sel = 2'b10;
                FSM_regWrite = 1'b1; //was 0
                FSM_memRDEN2 = 1'b1;
                FSM_memWE2 = 1'b0;
            end
                                                                                                         
            // S-type
            7'b0100011: begin //sb, sh, sw
                DCDR_alu_fun = 4'b0000;
                DCDR_alu_scra = 2'b00;
                DCDR_alu_scrb = 3'b010;
                FSM_memRDEN2 = 1'b1;
                FSM_memWE2 = 1'b1; // Since we're storing, its write enable. Cannot read and write at the same time
            end 
                                          
            // B-type
            7'b1100011: begin
                FSM_regWrite = 1'b0; //was 0
                FSM_memRDEN2 = 1'b0;
                FSM_memWE2 = 1'b0;
                DCDR_branch = 1'b1;         
            end
                   
            // U-type
            7'b0110111: begin //lui
                DCDR_alu_fun = 4'b1001;
                DCDR_alu_scra = 2'b01;
                DCDR_rf_wr_sel = 2'b11;
                FSM_regWrite = 1'b1;
                end                     
            7'b0010111: begin //auipc
                DCDR_alu_fun = 4'b0000;
                DCDR_alu_scra = 2'b01;
                DCDR_alu_scrb = 3'b011;
                DCDR_rf_wr_sel = 2'b11;
                FSM_regWrite = 1'b1;
                end  
                           
            // J-type
            7'b1101111: begin // jal
                DCDR_rf_wr_sel = 2'b00;
                FSM_regWrite = 1'b1;
                DCDR_jump = 1'b1;
                end    
        endcase
    end                     
endmodule
