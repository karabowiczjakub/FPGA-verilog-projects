# FPGA Verilog Projects

This repository contains selected FPGA laboratory projects implemented in Verilog using Xilinx Vivado.

The projects were developed as part of FPGA and reconfigurable systems laboratory work. The repository is organized into two main parts:

- `vision-pipeline` – FPGA-based image processing pipeline,
- `simple-processor` – simple custom processor implemented in Verilog.

## Projects

### Vision Pipeline

The vision pipeline project focuses on stream-based image processing on FPGA. The design processes image data pixel by pixel and preserves synchronization signals through the processing path.

Main topics:

- video signal processing,
- pixel stream processing,
- synchronization signals,
- pipeline latency,
- thresholding and basic image operations,
- Verilog modules and simulation.

### Simple Processor

The simple processor project contains an implementation of a basic custom processor in Verilog. The processor executes instructions stored in instruction memory and controls simple input/output peripherals such as switches and LEDs.

Main topics:

- instruction memory,
- data memory,
- program counter,
- registers,
- ALU,
- instruction decoding,
- conditional and unconditional jumps,
- simulation and FPGA implementation.

## Tools

- Xilinx Vivado
- Verilog HDL
- Zybo FPGA board

## Repository structure

```text
fpga-verilog-projects/
├── vision-pipeline/
│   ├── src/
│   ├── sim/
│   ├── constraints/
│   └── docs/
│
└── simple-processor/
    ├── src/
    ├── sim/
    ├── constraints/
    └── docs/
