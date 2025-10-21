`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Cal Poly
// Engineer: Binh To
// 
// Create Date: 10/26/2023 11:11:04 PM
// Module Name: BRANCH_COND_GEN
// Project Name: RISC-v OTTER MCU
// Target Devices: Basys3
// Description: This is a branch conditional generator. It takes two inputs in 
//              and compares them through three instructions (technically six but we only represent six because 
//              if one is true, then the other one must be false as they are mutually exclusive). 
//              Specifically, beq vs. bne, bge vs blt, and bgeu vs bltu. The first pair deals with equality. It checks if the two   
//              values are equal or not. The second pair checks if the first value is 
//              less than the second value or not when treated as signed numbers. The third and last pair also checks if the first 
//              value is less than the second value or not but they are treated as unsigned values.
//////////////////////////////////////////////////////////////////////////////////

module BRANCH_COND_GEN(
    input logic [31:0] BCG_condRs1,
    input logic [31:0] BCG_condRs2,
    input logic BCG_jump,
    input logic BCG_branch,
    input logic [2:0] branch_type,
    input logic jump_type,
    
    output logic [2:0] PC_source
    );
    logic BCG_br_eq;
    logic BCG_br_lt;
    logic BCG_br_ltu;
    
    always_comb begin
        PC_source = 3'b000;
        if (BCG_jump) begin
            PC_source = {1'b0, jump_type, 1'b1};  
        end
        else if (BCG_branch) begin
            BCG_br_eq = 1'b0;
            BCG_br_lt = 1'b0;
            BCG_br_ltu = 1'b0;
            
            if (BCG_condRs1 == BCG_condRs2)                         
                BCG_br_eq = 1'b1;
            if ($signed(BCG_condRs1) < $signed(BCG_condRs2))        
                BCG_br_lt = 1'b1;
            if ($unsigned(BCG_condRs1) < $unsigned(BCG_condRs2))    
                BCG_br_ltu = 1'b1;
            case (branch_type)
                    3'b000: // beq
                        if (BCG_br_eq == 1'b1) // If True, then branch
                            PC_source = 3'b010;
                    3'b001: // bne
                        if (BCG_br_eq == 1'b0   ) // If True, then branch was 0
                            PC_source = 3'b010;
                    3'b100: // blt
                        if (BCG_br_lt == 1'b1)
                            PC_source = 3'b010;
                    3'b110: // bltu
                        if (BCG_br_ltu == 1'b1)
                            PC_source = 3'b010;                                             
                    3'b101: // bge
                        if (BCG_br_eq == 1'b1 || BCG_br_lt == 1'b0)
                            PC_source = 3'b010;
                    3'b111: // bgeu
                        if (BCG_br_eq == 1'b1 || BCG_br_ltu == 1'b0)
                            PC_source = 3'b010;
            endcase 
        end
    end
endmodule
//                        if (BCG_br_eq == 1'b1 && BCG_br_lt == 1'b0) // if equal and not less than == if equal and greater than
//                            PC_source = 3'b010;
//                        else if (BCG_br_eq == 1'b0 && BCG_br_lt == 1'b0) // if not equal and not less than == if greater than
//                            PC_source = 3'b010;
//                        else 
//                            PC_source = 3'b000;

//                        if (BCG_br_eq == 1'b1 && BCG_br_ltu == 1'b0) // if equal and not less than == if equal and greater than
//                            PC_source = 3'b010;
//                        else if (BCG_br_eq == 1'b0 && BCG_br_ltu == 1'b0) // if not equal and not less than == if greater than
//                            PC_source = 3'b010;
//                        else 
//                            PC_source = 3'b000; 