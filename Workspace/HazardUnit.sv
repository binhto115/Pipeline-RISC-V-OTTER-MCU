`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/22/2024 12:50:58 PM
// Design Name: 
// Module Name: HazardUnit
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module HazardUnit(
    input logic [4:0] ExecuteRs1,
    input logic [4:0] ExecuteRs2,
    
    input logic [4:0] DecodeRs1,
    input logic [4:0] DecodeRs2,
    input logic [4:0] ExecuteRD,
    input logic [1:0] hazard_rf_wr_sel,
  
        
    input logic MemRegWrite,
    input logic WbRegWrite,
    input logic [4:0] MemWD,
    input logic [4:0] WbWD,
    
    input logic [2:0] Execute_pc_source,
    
    output logic [1:0] ForwardAE,
    output logic [1:0] ForwardBE, 
    
    output logic StallF,
    output logic StallD,
    output logic FlushE,
    output logic FlushD
    );
    
    logic lwStall;
    
    always_comb begin
        ForwardAE = 2'b0;
        ForwardBE = 2'b0;
        StallF = 1'b0;
        StallD = 1'b0;
        FlushE = 1'b0;
        FlushD = 1'b0;
        lwStall = 1'b0;
    
    // Forwarding
        // For Rs1
        if ((ExecuteRs1 == MemWD) && (MemRegWrite == 1'b1) && ExecuteRs1 != 5'b0)
            ForwardAE = 2'b10;
        else if ((ExecuteRs1 == WbWD) && (WbRegWrite == 1'b1) && ExecuteRs1 != 5'b0)
            ForwardAE = 2'b01;
        else
            ForwardAE = 2'b00;

        // For Rs2   
        if ((ExecuteRs2 == MemWD) && (MemRegWrite == 1'b1) && ExecuteRs2 != 5'b0)
            ForwardBE = 2'b10;
        else if ((ExecuteRs2 == WbWD) && (WbRegWrite == 1'b1) && ExecuteRs2 != 5'b0)    
            ForwardBE = 2'b01;
        else
            ForwardBE = 2'b00;
            
    // Stall for LW
        if (((DecodeRs1 == ExecuteRD) || (DecodeRs2 == ExecuteRD)) && hazard_rf_wr_sel == 2'b10)
            lwStall = 1'b1;   
        else
            lwStall = 1'b0;
    // Branching
        if (Execute_pc_source != 3'b000)
            begin
            FlushD = 1'b1;
            FlushE = 1'b1;
            end
        else if (lwStall == 1'b1)
            FlushE = 1'b1;
        else
            begin
            FlushD = 1'b0;
            FlushE = 1'b0;
            end       
    end
    
    assign StallF = lwStall;
    assign StallD = lwStall; 
            
endmodule
