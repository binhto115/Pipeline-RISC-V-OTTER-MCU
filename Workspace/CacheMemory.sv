`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/15/2024 10:32:28 AM
// Design Name: 
// Module Name: CacheMemory
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


module Cache(
    input CLK, RST,
    input [31:0] address_In, data_In,
    input write_EN, Hit_In,
    output logic Hit_Out,
    output logic [31:0] cache_Out
    );
    
    
    /* Tag, Index, Byte offset */
    
    logic [1:0] byte_Offset;
    logic [3:0] index;
    logic [25:0] tag;
    
    /* Set Block */
    // 16 blocks 60 bits wide
    logic [59:0] Set0 [15:0]; 
    logic [59:0] Set1 [15:0];
    logic [59:0] Set2 [15:0];
    logic [59:0] Set3 [15:0];
    
    /*---------- Valid bits ----------*/
    logic Valid0, Valid1, Valid2, Valid3;
    
    /*---------- Dirty bits ----------*/
    logic dirty_Bit0, dirty_Bit1, dirty_Bit2, dirty_Bit3;
    
    /*---------- Set tags ----------*/
    logic [25:0] Tag0, Tag1, Tag2, Tag3;
    
    /*---------- Set data ----------*/
    logic [31:0] Data0, Data1, Data2, Data3;
    
    /*---------- Comparator matches ----------*/
    logic Match0, Match1, Match2, Match3;
    
    /*---------- Selector bits ----------*/
    logic set0_Sel, set1_Sel, set2_Sel, set3_Sel;
    
    /*---------- Mux select ----------*/
    logic [3:0] cache_Sel;
    
/*---------- Initialize cache ----------*/
    initial
        begin
            for(int i = 0; i <= 15; i++)
                begin
                    Set0[i] = 0;
                    Set1[i] = 0;
                    Set2[i] = 0;
                    Set3[i] = 0;
                end
        end
        
        /*---------- Sequential logic for writing to cache ----------*/
        always_ff @(posedge CLK)
            begin
                // attempt to read from cache first
                // if valid bit = 0, block is empty == miss
                // if miss, grab data from elsewhere (where?)
                // use byte_offset to determine which set to write to? Case statement?
                // use index to determine which block
                // after write set valid bit to 1
            end
    
    /*---------- Combinational logic for reading from cache ----------*/
    always_comb
        begin
        
            /*---------- Tag, index, byte offset ----------*/
            // Based on [31:0] instruction data
    byte_Offset = address_In[1:0];
    index = address_In[5:2];
    tag = address_In[31:6];
    
    /*---------- Valid bits ----------*/
    Valid0 = Set0[index][59];
    Valid1 = Set1[index][59];
    Valid2 = Set2[index][59];
    Valid3 = Set3[index][59];
    
    /*---------- Dirty bits ----------*/
    dirty_Bit0 = Set0[index][58];
    dirty_Bit1 = Set1[index][58];
    dirty_Bit2 = Set2[index][58];
    dirty_Bit3 = Set3[index][58];
    
    /*---------- Set tags ----------*/
    Tag0 = Set0[index][57:32];
    Tag1 = Set1[index][57:32];
    Tag2 = Set2[index][57:32];
    Tag3 = Set3[index][57:32];
    
    /*---------- Set data ----------*/
    Data0 = Set0[index][31:0];
    Data1 = Set1[index][31:0];
    Data2 = Set2[index][31:0];
    Data3 = Set3[index][31:0];
    
    /*---------- Comparator matches ----------*/
    Match0 = (tag == Tag0);
    Match1 = (tag == Tag1);
    Match2 = (tag == Tag2);
    Match3 = (tag == Tag3);
    
    /*---------- Selector bits ----------*/
    set0_Sel = (Valid0 && Match0);
    set1_Sel = (Valid1 && Match1);
    set2_Sel = (Valid2 && Match2);
    set3_Sel = (Valid3 && Match3);
    
    /*---------- Mux select ----------*/
    cache_Sel = {set3_Sel, set2_Sel, set1_Sel, set0_Sel};
        
    Hit_Out = (set0_Sel || set1_Sel || set2_Sel || set3_Sel);
            
            case(cache_Sel)
                    4'b0001: cache_Out = Data0;
                    4'b0010: cache_Out = Data1;
                    4'b0100: cache_Out = Data2;
                    4'b1000: cache_Out = Data3;
                    default: cache_Out = 32'hDEAD_DEAD;
                endcase
        end
endmodule
