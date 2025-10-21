# Pipeline-RISC-V-OTTER-MCU

The Pipeline RISC-V OTTER MCU is an enhanced version of the original OTTER single-core microcontroller, redesigned with a five-stage pipelined datapath to improve instruction throughput and execution efficiency. The project is implemented in SystemVerilog and deployed on a Xilinx Artix-7 FPGA.

⚙️ Overview
This microcontroller follows the RV32I base integer instruction set and adopts the standard five-stage pipeline model used in modern RISC architectures:
Instruction Fetch (IF)
Instruction Decode (ID)
Execute (EX)
Memory Access (MEM)
