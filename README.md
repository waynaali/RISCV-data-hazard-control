# 5-Stage Pipelined RISC-V Processor: Data Hazard Control

## Overview
This repository contains the **design and verification** of a **5-stage pipelined RISC-V processor** with a focus on **data hazard management**. The project implements techniques to handle **RAW (Read After Write) hazards**, including **load-use hazard stalling (lwStall)** and **operand forwarding**.

> ⚠ Note: This project is **designed and verified** using SystemVerilog; it is not physically implemented.

---

## Features

- **5-Stage Pipeline:** IF → ID → EX → MEM → WB  
- **Data Hazard Detection:**  
  - Load-use hazard detection with automatic stalling  
- **Forwarding Unit:**  
  - Resolves RAW hazards by forwarding operands from EX/MEM and MEM/WB stages  
- **Modular Design:**  
  - Separate control unit, datapath, and hazard unit for clarity  
- **Verification:**  
  - SystemVerilog testbenches with waveform-level validation

---

## Folder Structure

```

Pipelined_riscv_datahazardcontrol/
│
├── srcs/             # RTL source files
│   ├── ALU.sv
│   ├── HazardUnit.sv
│   ├── CONTROL_UNIT.sv
│   └── ...
│
├── tb/               # Testbenches and simulation configs
│   ├── tb.sv
│   └── tb_risc_behav2.wcfg
│
├── instr_memory/     # Instruction memory files
│   └── inst.mem
│
├── doc/              # Diagrams and waveforms
│   ├── block_diagram.png
│   └── waveform.png
│
└── README.md         # Project documentation

```

---

## Design Highlights

### lwStall (Load-Use Hazard)
- Detects when a **load (`lw`) instruction** is immediately followed by an instruction that uses its result  
- Inserts a **pipeline stall** in the EX stage to maintain correctness

### Forwarding Unit
- Forwards operands from **EX/MEM** and **MEM/WB** to the EX stage  
- Minimizes stalls and improves pipeline efficiency

### Verification
- Testbenches simulate common **hazard-prone instruction sequences**  
- Waveform inspection ensures **correct stalling and forwarding behavior**  
- Signals verified: `lwStall`, `ForwardA`, `ForwardB`, etc.

---

## Tools Used
- **SystemVerilog** (RTL design)  
- **Xilinx Vivado / Simulation** (waveform verification)  

---

## Future Scope
- Control hazard handling (branch prediction)  
- Integration with cache/memory hierarchy  
- Performance optimization and timing analysis

---

## License
This project is **open source** for educational purposes.  

---

## Author
Wayna Ali  
- GitHub: [https://github.com/waynaali](https://github.com/waynaali)  
- LinkedIn: [https://www.linkedin.com/in/wayna-ali-055204209/v]  
