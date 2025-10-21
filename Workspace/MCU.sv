`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Cal Poly
// Engineer: Binh To
// 
// Create Date: 11/08/2023 03:10:16 AM
// Design Name: RISC-V Otter MCU
// Module Name: MCU
// Project Name: RISC-V Otter MCU
// Target Devices: Basys3
// Description: The micro-controller consisted  of Program Counter, Memory, register File, ALU, 
//              Immediate Generator, Branch Condition Generator, and Control Unit as subcomponents.
//              Note: csr module is excluded as it iw out of scope within the bound of this assignemnt. 
//////////////////////////////////////////////////////////////////////////////////

        
typedef struct packed {
    logic [4:0] addr1_instruction_to_rf;
    logic [4:0] addr2_instruction_to_rf;
    logic [4:0] wa_instruction_to_rf;

    logic [31:0] NextInstructionAddress;
    logic [31:0] pc_wire;
    logic [31:0] ir_wire; 
    
    
    logic [31:0] rf_rs1_wire;
    logic [31:0] rf_rs2_wire;    
    logic [1:0] rf_wr_sel_wire; 
        
    //Decode
    logic [3:0] alu_fun_wire;
    logic [1:0] alu_srca_wire;
    logic [2:0] alu_srcb_wire;
    logic [31:0] aluResult_wire;    
    logic [31:0] aluMUXA_to_alu_wire;
    logic [31:0] aluMUXB_to_alu_wire;
        
    // FSM Signal    
    logic fsm_reg_write;
    logic fsm_memWE2;
    logic fsm_memRDEN2; 
     
    logic [1:0] MEM_SIZE;
    logic MEM_SIGN;
    
    logic [31:0] BAG_to_jalr_wire; 
    logic [31:0] BAG_to_branch_wire; 
    logic [31:0] BAG_to_jal_wire; 
    logic [31:0] mtvec_to_4_wire; 
    logic [31:0] mepc_to_5_wire; 
    
    logic [31:0] btype_wire;
    logic [31:0] jtype_wire; 
    logic [31:0] itype_wire;
    logic [31:0] utype_wire;
    logic [31:0] stype_wire;
    
    // Branch Cond
    logic jump;
    logic branch;
    logic [31:0] Dout2_wire;
    logic [31:0] hazardB_to_alu;
    //logic [2:0] funt3;  


} instr_t;

module MCU(
    input logic MCU_RST,
    input logic MCU_INTR,
    input logic [31:0] MCU_IOBUS_IN,
    input logic MCU_clk,
    output logic MCU_IOBUS_WR,
    output logic [31:0] MCU_IOBUS_OUT,
    output logic [31:0] MCU_IOBUS_ADDR
    );

    // Control Unit  
//    logic fsm_csr_we;           // Unused
//    logic fsm_int_taken;        // Unused
//    logic fsm_mret_exec;        // Unused
    logic [31:0] csr_RD_wire = 32'b0;


/*--------------------------------------------------------------------------------------------*/  
/*--------------------------------------------------------------------------------------------*/  
    // Hazard Units
    logic stallF;
    logic stallD;

    // Program Counter 
    logic [31:0] pc_wire;
    logic [31:0] din_wire;
    logic [31:0] ir_wire; 


    Program_Counter OTTER_PC (
    .PC_WRITE   (~stallF),
    .PC_RST     (MCU_RST),
    .PC_DIN     (din_wire),
    .PC_CLK     (MCU_clk),
    .PC_COUNT   (pc_wire)  );      
/*--------------------------------------------------------------------------------------------*/  
/*--------------------------------------------------------------------------------------------*/   
    // Plus4Adder
    logic [31:0] NextInstructionAddress;   
    assign NextInstructionAddress = pc_wire + 4;   
/*--------------------------------------------------------------------------------------------*/    
/*--------------------------------------------------------------------------------------------*/
    logic jump;
    logic branch;
    logic fsm_reg_write;
    logic fsm_memWE2;
    logic fsm_memRDEN2; 
    logic [3:0] alu_fun_wire;
    logic [1:0] alu_srca_wire;
    logic [2:0] alu_srcb_wire;
    logic [1:0] rf_wr_sel_wire; 
        
     //CONTROL UNIT DECODER 
    CU_DCDR OTTER_CU_DCDR (
    .DCDR_ir_opcode     (FetchReg.ir_wire[6:0]),
    .DCDR_ir_funct      (FetchReg.ir_wire[14:12]),
    .DCDR_ir_30         (FetchReg.ir_wire[30]),
    .DCDR_int_taken     (),
    
    .DCDR_jump          (jump),
    .DCDR_branch        (branch),
    .FSM_regWrite       (fsm_reg_write),
    .FSM_memWE2         (fsm_memWE2),
    .FSM_memRDEN2       (fsm_memRDEN2),
    .DCDR_alu_fun       (alu_fun_wire),
    .DCDR_alu_scra      (alu_srca_wire),
    .DCDR_alu_scrb      (alu_srcb_wire),
    .DCDR_rf_wr_sel     (rf_wr_sel_wire)  );
/*--------------------------------------------------------------------------------------------*/
/*--------------------------------------------------------------------------------------------*/
    // Memory   
    logic [1:0] MEM_SIZE;
    logic MEM_SIGN;
    logic [13:0] pc_to_addr1_wire;
    
    logic [31:0] hazardA_to_alu;
    logic [31:0] hazardB_to_alu; // Din2

    assign pc_to_addr1_wire = pc_wire[15:2];
    assign MEM_SIZE = Execute.ir_wire[13:12];
    assign MEM_SIGN = Execute.ir_wire[14];
    logic [31:0] Dout1_instruction_wire; 
    logic [31:0] Dout2_wire; 
        
    //Otter Memory 
     Memory OTTER_MEMORY (
    .MEM_CLK   (MCU_clk), //1
    .MEM_RDEN1 (~stallF), //1
    .MEM_RDEN2 (Execute.fsm_memRDEN2), //2
    .MEM_WE2   (Execute.fsm_memWE2),
    .MEM_ADDR1 (pc_to_addr1_wire), //1
    .MEM_ADDR2 (Execute.aluResult_wire),
    .MEM_DIN2  (Execute.hazardB_to_alu), //2
    .MEM_SIZE  (MEM_SIZE), //2
    .MEM_SIGN  (MEM_SIGN), //2
    
    .IO_IN     (MCU_IOBUS_IN), //1
    .IO_WR     (MCU_IOBUS_WR), //1
    
    .MEM_DOUT1 (Dout1_instruction_wire), //1
    .MEM_DOUT2 (Dout2_wire)  ); //2
/*--------------------------------------------------------------------------------------------*/
/*--------------------------------------------------------------------------------------------*/ 
    logic [31:0] rf_rs1_wire;
    logic [31:0] rf_rs2_wire;
    logic [31:0] wd_wire;
    //logic [4:0] wa_instruction_to_rf;
        
    REG_FILE OTTER_REG_FILE (
    .RF_ADR1    (FetchReg.ir_wire[19:15]), 
    .RF_ADR2    (FetchReg.ir_wire[24:20]),
    .RF_WA      (Memory.ir_wire[11:7]),
    .RF_WD      (wd_wire), //2
    .RF_CLK     (MCU_clk), //1
    .RF_EN      (Memory.fsm_reg_write), //2
    .RF_RS1     (rf_rs1_wire), //1
    .RF_RS2     (rf_rs2_wire)  ); //1   
    
    assign MCU_IOBUS_OUT = hazardB_to_alu;
    //assign for IOBUS_IN and IOBUS_ADDR;
/*--------------------------------------------------------------------------------------------*/
/*--------------------------------------------------------------------------------------------*/
    logic [31:0] BAG_to_jalr_wire; // goes to 1
    logic [31:0] BAG_to_branch_wire; // goes to 2
    logic [31:0] BAG_to_jal_wire; // goes to 3
//    logic [31:0] mtvec_to_4_wire; // goes to 4  UNUSED
//    logic [31:0] mepc_to_5_wire; // goes to 5   UNUSED 
    logic [31:0] btype_wire;
    logic [31:0] jtype_wire; 
    logic [31:0] utype_wire;
    logic [31:0] itype_wire;
    logic [31:0] stype_wire;
      
    // Immediate Generator
    IMMED_GEN OTTER_IMMED_GEN (
    .IG_instruction     (FetchReg.ir_wire),
    .IG_utype           (utype_wire),
    .IG_itype           (itype_wire),
    .IG_stype           (stype_wire),
    .IG_btype           (btype_wire),
    .IG_jtype           (jtype_wire)  );
/*--------------------------------------------------------------------------------------------*/   
/*--------------------------------------------------------------------------------------------*/

    // BRANCH_ADDR_GENERATOR
    BRANCH_ADDR_GEN OTTER_BAG (
    .BAG_pc         (Decode.pc_wire),
    .BAG_jtype      (Decode.jtype_wire),
    .BAG_btype      (Decode.btype_wire),
    .BAG_rs1        (hazardA_to_alu),
    .BAG_itype      (Decode.itype_wire),
    
    .BAG_jalr       (BAG_to_jalr_wire),
    .BAG_branch     (BAG_to_branch_wire),
    .BAG_jal        (BAG_to_jal_wire)  ); 
/*--------------------------------------------------------------------------------------------*/
/*--------------------------------------------------------------------------------------------*/ 
    logic opcode4;
    logic [2:0] funt3;  
    logic [2:0] pc_source_wire; 
    assign opcode4 = Decode.ir_wire[3];
    assign funt3 = Decode.ir_wire[14:12];


    // Branch_Cond_Generator
    BRANCH_COND_GEN OTTER_BCG (
    .BCG_condRs1    (hazardA_to_alu),
    .BCG_condRs2    (hazardB_to_alu),
    .BCG_jump       (Decode.jump),
    .BCG_branch     (Decode.branch),
    .branch_type    (funt3),  
    .jump_type      (opcode4),
    
    .PC_source      (pc_source_wire) );

/*--------------------------------------------------------------------------------------------*/
/*--------------------------------------------------------------------------------------------*/
    //Hazard Datector
    logic [1:0] forwardAE;
    logic [1:0] forwardBE;
    logic flushE;
    logic flushD;
    
    HazardUnit hazardDetect (
    // Forwarding
    .ExecuteRs1         (Decode.ir_wire[19:15]),
    .ExecuteRs2         (Decode.ir_wire[24:20]),
    
    //Stall lw
    .DecodeRs1          (FetchReg.ir_wire[19:15]),
    .DecodeRs2          (FetchReg.ir_wire[24:20]),
    .ExecuteRD          (Decode.ir_wire[11:7]),
    .hazard_rf_wr_sel   (Decode.rf_wr_sel_wire),
    
    // Forwarding
    .MemRegWrite        (Execute.fsm_reg_write),
    .WbRegWrite         (Memory.fsm_reg_write),
    .MemWD              (Execute.ir_wire[11:7]),
    .WbWD               (Memory.ir_wire[11:7]),
    
    //Branch
    .Execute_pc_source  (pc_source_wire),
    
    // Forward
    .ForwardAE          (forwardAE),
    .ForwardBE          (forwardBE),
    
    // Stall
    .StallF             (stallF),
    .StallD             (stallD),
    
    // Flush
    .FlushE             (flushE),
    .FlushD             (flushD)
    );

/*--------------------------------------------------------------------------------------------*/
/*--------------------------------------------------------------------------------------------*/  
    // ALU
    logic [31:0] aluResult_wire;    
    logic [31:0] aluMUXA_to_alu_wire;
    logic [31:0] aluMUXB_to_alu_wire;   

    ALU OTTER_ALU(
    .ALU_scra   (hazardA_to_alu),
    .ALU_scrb   (hazardB_to_alu),
    .ALU_fun    (Decode.alu_fun_wire),
    .ALU_result (aluResult_wire)  
    ); 
    
    assign MCU_IOBUS_ADDR = Execute.aluResult_wire;
/*--------------------------------------------------------------------------------------------*/
/*--------------------------------------------------------------------------------------------*/
    // Program Counter Mux
    always_comb begin
        case (pc_source_wire)
            3'b000: din_wire = NextInstructionAddress;
            3'b001: din_wire = BAG_to_jalr_wire;//Execute.BAG_to_jalr_wire;
            3'b010: din_wire = BAG_to_branch_wire;//Execute.BAG_to_branch_wire;
            3'b011: din_wire = BAG_to_jal_wire; //Execute.BAG_to_jal_wire;
            3'b100: din_wire = 0; 
            3'b101: din_wire = 0;
            default: din_wire = 32'h0;
        endcase
    end
 /*--------------------------------------------------------------------------------------------*/
    // Reg File Mux
    always_comb begin
        case(Memory.rf_wr_sel_wire)
            2'b00: wd_wire = Memory.NextInstructionAddress;
            2'b01: wd_wire = csr_RD_wire; //Execute.result
            2'b10: wd_wire = Memory.Dout2_wire; //
            2'b11: wd_wire = Memory.aluResult_wire;
            default: wd_wire = 32'b0;
        endcase
    end
/*--------------------------------------------------------------------------------------------*/
    // ALU SRCA MUX
    always_comb begin
        case (alu_srca_wire)//Decode.alu_srca_wire)
            2'b00: aluMUXA_to_alu_wire = rf_rs1_wire;//Decode.rf_rs1_wire;
            2'b01: aluMUXA_to_alu_wire = utype_wire;//Decode.utype_wire;
            2'b10: aluMUXA_to_alu_wire = ~rf_rs1_wire;//~(Decode.rf_rs1_wire);
            default: aluMUXA_to_alu_wire = 32'b0;
        endcase
    end  
/*--------------------------------------------------------------------------------------------*/   
    // ALU SRCB MUX    
    always_comb begin
        case (alu_srcb_wire)//Decode.alu_srcb_wire)
            3'b000: aluMUXB_to_alu_wire = rf_rs2_wire;//Decode.rf_rs2_wire;
            3'b001: aluMUXB_to_alu_wire = itype_wire;//Decode.itype_wire;
            3'b010: aluMUXB_to_alu_wire = stype_wire;//Decode.stype_wire;
            3'b011: aluMUXB_to_alu_wire = FetchReg.pc_wire;//Decode.pc_wire;
            3'b100: aluMUXB_to_alu_wire = csr_RD_wire; //for future use
            default: aluMUXB_to_alu_wire = 32'b0;
        endcase
    end  
 /*--------------------------------------------------------------------------------------------*/
  // Hazard MUX A
    always_comb begin
        case(forwardAE)
            2'b00: hazardA_to_alu = Decode.aluMUXA_to_alu_wire;
            2'b01: hazardA_to_alu = wd_wire;
            2'b10: hazardA_to_alu = Execute.aluResult_wire;
            default: hazardA_to_alu = 32'b0;
        endcase
    end
 /*-------------------------------------------------------------------------------------------*/
  // Hazard MUX B
    always_comb begin
        case(forwardBE)
            2'b00: hazardB_to_alu = Decode.aluMUXB_to_alu_wire;
            2'b01: hazardB_to_alu = wd_wire;
            2'b10: hazardB_to_alu = Execute.aluResult_wire;
            default: hazardB_to_alu = 32'b0;
        endcase
    end
/*--------------------------------------------------------------------------------------------*/

    // Fetch => Decode
    instr_t FetchReg;
    always_ff @(posedge MCU_clk) 
    begin
    if (MCU_RST) 
        FetchReg <= '0;
    else if (stallD == 1'b1)
        begin
            FetchReg <= FetchReg;
        end
    else if (flushD == 1'b1)
        begin
            FetchReg <= '0;
        end
    else 
        begin
        // "takes in..."
        FetchReg.pc_wire <= pc_wire; // pc_count
        FetchReg.NextInstructionAddress <= NextInstructionAddress; //pc+4
        FetchReg.ir_wire <= Dout1_instruction_wire;
        end
    end
/*--------------------------------------------------------------------------------------------*/
    // Decode => Execute
    instr_t Decode;
    always_ff @(posedge MCU_clk) 
    begin
    if (MCU_RST) 
        Decode <= '0;
    else if (flushE == 1'b1)
        begin
        Decode <= '0;
        end
    else 
        begin
        // PC to Decode
        Decode.pc_wire <= FetchReg.pc_wire;
        Decode.NextInstructionAddress <= FetchReg.NextInstructionAddress;
        
        // IR to Decode
        Decode.ir_wire <= FetchReg.ir_wire;
        
        // From Imm Gen to Decode
        Decode.jtype_wire <= jtype_wire;
        Decode.btype_wire <= btype_wire;
        Decode.utype_wire <= utype_wire;
        Decode.itype_wire <= itype_wire;
        Decode.stype_wire <= stype_wire;
        
        // DCDR to Decode
        Decode.jump <= jump;
        Decode.branch <= branch;
        Decode.fsm_reg_write <= fsm_reg_write;
        Decode.fsm_memWE2 <= fsm_memWE2;
        Decode.fsm_memRDEN2 <= fsm_memRDEN2;
        Decode.alu_fun_wire <= alu_fun_wire;        
        Decode.rf_wr_sel_wire <= rf_wr_sel_wire;

        // RF to Decode
        Decode.aluMUXA_to_alu_wire <= aluMUXA_to_alu_wire;
        Decode.aluMUXB_to_alu_wire <= aluMUXB_to_alu_wire;
        // to BCG
        Decode.rf_rs1_wire <= rf_rs1_wire;
        Decode.rf_rs2_wire <= rf_rs2_wire;
       
        end
    end
/*--------------------------------------------------------------------------------------------*/   
    // Execute => Memory
    instr_t Execute;
    always_ff @(posedge MCU_clk) 
    begin
    if (MCU_RST) 
        Execute <= '0;
    else 
        begin
        // PC route
        Execute.pc_wire <= Decode.pc_wire;
        Execute.NextInstructionAddress <= Decode.NextInstructionAddress;
        
        Execute.fsm_memRDEN2 <= Decode.fsm_memRDEN2;
        Execute.fsm_reg_write <= Decode.fsm_reg_write;
        Execute.rf_wr_sel_wire <= Decode.rf_wr_sel_wire;
        Execute.fsm_memWE2 <= Decode.fsm_memWE2;
                        
        Execute.ir_wire <= Decode.ir_wire; // For write adress (wa)
        Execute.aluResult_wire <= aluResult_wire;
        Execute.rf_rs2_wire <= Decode.rf_rs2_wire;  
        Execute.hazardB_to_alu <= hazardB_to_alu;      
        end
    end
/*--------------------------------------------------------------------------------------------*/
    // Memory => WriteBack
    instr_t Memory;
    always_ff @(posedge MCU_clk) 
    begin
    if (MCU_RST) 
        Memory <= '0;
    else 
        begin
        //DCDR to Mem
        Memory.fsm_reg_write <= Execute.fsm_reg_write;        
        Memory.rf_wr_sel_wire <= Execute.rf_wr_sel_wire;
        // ALU to Mem
        Memory.aluResult_wire <= Execute.aluResult_wire;
        Memory.Dout2_wire <= Dout2_wire;
        // IR to mem
        Memory.ir_wire <= Execute.ir_wire;
        // PC route
        Memory.NextInstructionAddress <= Execute.NextInstructionAddress;

        // Memory to outputs
        MCU_IOBUS_ADDR <= Execute.aluResult_wire;
        MCU_IOBUS_OUT <= Execute.rf_rs2_wire;
       
        end
    end
/*--------------------------------------------------------------------------------------------*/
/*--------------------------------------------------------------------------------------------*/
    assign MCU_IOBUS_ADDR = Execute.aluResult_wire;

endmodule
