
# Simple Verilog Processor

This folder contains a simple custom processor implemented in Verilog as part of FPGA / reconfigurable systems laboratory classes.

The project was developed using Xilinx Vivado. The processor executes 32-bit instructions stored in instruction memory, performs basic ALU operations, supports conditional and unconditional jumps, and can communicate with simple external I/O signals.

In the final version, the processor is connected to switches and LEDs on the FPGA board. The example program turns LEDs on sequentially, waits for switch input, and uses delay loops so that each LED remains visible for approximately one second.

## Project overview

The main goal of this project was to understand how a very simple processor can be built in FPGA logic.

Unlike a normal software program running on an existing CPU, this project describes the CPU itself in Verilog. The design includes:

* instruction memory,
* data memory,
* program counter,
* registers,
* ALU,
* instruction decoder,
* multiplexers,
* input/output interface,
* testbenches for simulation,
* top-level module for FPGA implementation.

The processor fetches an instruction from instruction memory, decodes its fields, selects operands using multiplexers, performs an ALU operation, writes the result to a selected register and updates the program counter.

## Repository structure

Recommended structure of this project:

```text
simple-processor/
├── README.md
├── src/
│   ├── processor.v
│   ├── i_mem.v
│   ├── d_mem.v
│   └── top.v
│
├── sim/
│   ├── tb_processor.v
│   └── tb_13_2.v
│
├── constraints/
│   └── ZYBO_Master.xdc
│
└── docs/
    └── screenshots/
```

## File description

| File              | Recommended location | Description                                                                |
| ----------------- | -------------------- | -------------------------------------------------------------------------- |
| `processor.v`     | `src/`               | Main processor implementation                                              |
| `i_mem.v`         | `src/`               | Instruction memory with the example program                                |
| `d_mem.v`         | `src/`               | Simple data memory                                                         |
| `top.v`           | `src/`               | FPGA top module connecting the processor to switches, LEDs and board clock |
| `tb_processor.v`  | `sim/`               | Testbench for the LED/switch program                                       |
| `tb_13_2.v`       | `sim/`               | Testbench for basic processor instructions                                 |
| `ZYBO_Master.xdc` | `constraints/`       | FPGA pin constraints for clock, switches and LEDs                          |

## Processor architecture

The processor has an 8-bit datapath and executes 32-bit instructions.

Main internal elements:

* `PC` – program counter,
* `i_mem` – instruction memory,
* `d_mem` – data memory,
* `R0`–`R4` – internal registers,
* `R5` – input register connected to `gpi`,
* `R6` – constant zero register,
* ALU,
* operand multiplexers,
* writeback multiplexer,
* program counter multiplexer.

The external processor interface is:

```verilog
module processor(
    input clk,
    input [7 : 0] gpi,
    output [7 : 0] gpo
);
```

### Register usage

| Register    | Role                                                                  |
| ----------- | --------------------------------------------------------------------- |
| `R0`        | general-purpose register, also used as counter and condition register |
| `R1`        | general-purpose register                                              |
| `R2`        | general-purpose register                                              |
| `R3`        | general-purpose register                                              |
| `R4`        | output register connected to `gpo`                                    |
| `R5`        | input register connected to `gpi`                                     |
| `R6`        | constant zero                                                         |
| `PC` / `R7` | program counter                                                       |

In the I/O program:

```text
R4 = output register
R5 = input register
R0 = helper register / delay counter / condition register
```

The output is assigned directly from `R4`:

```verilog
assign gpo = r4;
```

The input register `R5` is connected directly to the external input port:

```verilog
assign r5 = gpi;
```

## Instruction format

Each instruction is 32 bits wide.

The instruction layout used in this project is:

```verilog
instr = {6'b000000, pc_op, 2'b00, alu_op, 1'b0, rx_op, imm_op, ry_op, rd_op, d_op, imm}
```

The fields are decoded in `processor.v` as:

```verilog
assign pc_op  = instr[25:24];
assign alu_op = instr[21:20];
assign rx_op  = instr[18:16];
assign imm_op = instr[15];
assign ry_op  = instr[14:12];
assign rd_op  = instr[11];
assign d_op   = instr[10:8];
assign imm    = instr[7:0];
```

### Field meaning

| Field    | Meaning                                                  |
| -------- | -------------------------------------------------------- |
| `pc_op`  | controls program counter update                          |
| `alu_op` | selects ALU operation                                    |
| `rx_op`  | selects first ALU operand                                |
| `imm_op` | selects second ALU operand source: register or immediate |
| `ry_op`  | selects second register operand                          |
| `rd_op`  | selects writeback source: ALU or data memory             |
| `d_op`   | selects destination register                             |
| `imm`    | 8-bit immediate value                                    |

## Multiplexers and ALU

### Operand selection

The `rx_op` field selects the first ALU operand:

```text
0 -> R0
1 -> R1
2 -> R2
3 -> R3
4 -> R4
5 -> R5
6 -> R6
7 -> PC
```

The `ry_op` field selects the second register operand in the same way.

The `imm_op` field selects the second ALU input:

```verilog
assign alu_y = (imm_op == 1'b1) ? imm : ry;
```

So:

```text
imm_op = 0 -> second ALU operand comes from selected register RY
imm_op = 1 -> second ALU operand comes from immediate value imm
```

### ALU operations

The ALU supports four operations:

| `alu_op` | Operation    | Meaning                      |
| -------- | ------------ | ---------------------------- |
| `0`      | `AND`        | bitwise AND                  |
| `1`      | `ADD`        | addition                     |
| `2`      | compare zero | returns `1` if `rx == 0`     |
| `3`      | pass value   | passes `alu_y` to the output |

The compare signal is generated as:

```verilog
assign cmp_res = (rx == 8'd0);
```

The `pass value` operation is important for jumps. Jump target addresses are stored in the immediate field, but the program counter loads its next value from `alu_res`. Therefore, during jumps the ALU passes `imm` to `alu_res`.

## Program counter operation

The program counter normally increments by one:

```text
PC = PC + 1
```

For jump instructions, the next value of `PC` is taken from the ALU result:

```verilog
assign pc_next = (pc_jump == 1'b1) ? alu_res : (pc + 8'd1);
```

The `pc_op` field controls jump behavior:

| `pc_op` | Operation               |
| ------- | ----------------------- |
| `0`     | no jump, `PC = PC + 1`  |
| `1`     | unconditional jump      |
| `2`     | jump if zero, `jz`      |
| `3`     | jump if not zero, `jnz` |

For example:

```asm
jz R0, 0x0A
```

means:

```text
if R0 == 0:
    PC = 0x0A
else:
    PC = PC + 1
```

## Supported instruction examples

This project uses a small set of simple instructions.

### `movi`

Example:

```asm
movi R4, 0x01
```

Meaning:

```text
R4 = 0x01
```

Internally this is implemented as:

```text
R4 = R6 + imm
```

because `R6` is always zero.

### `mov`

Example from the testbench:

```asm
mov R1, R0
```

Meaning:

```text
R1 = R0
```

Internally this is implemented as:

```text
R1 = R0 + R6
```

### `addi`

Example:

```asm
addi R0, R0, 0x01
```

Meaning:

```text
R0 = R0 + 1
```

This is used in delay loops.

### `andi`

Example:

```asm
andi R0, R5, 0x01
```

Meaning:

```text
R0 = R5 & 0x01
```

This checks the state of `SW0`.

Another example:

```asm
andi R0, R5, 0x02
```

checks the state of `SW1`.

### `jz`

Example:

```asm
jz R0, 0x0A
```

Meaning:

```text
if R0 == 0:
    jump to instruction 0x0A
```

This is used both for delay loops and for waiting for switch input.

### `jump`

Example:

```asm
jump 0x00
```

Meaning:

```text
PC = 0x00
```

This returns the program to the beginning.

## Example program in instruction memory

The main program is stored in `i_mem.v`.

Readable assembly version:

```asm
0:  movi R4, 0x01      ; turn on LED0
1:  movi R0, 0xF0      ; initialize delay counter

2:  addi R0, R0, 0x01  ; increment delay counter
3:  jz   R0, 0x05      ; if R0 == 0, end delay
4:  jump 0x02          ; otherwise repeat delay loop

5:  movi R4, 0x02      ; turn on LED1
6:  movi R0, 0xF0      ; initialize delay counter

7:  addi R0, R0, 0x01  ; increment delay counter
8:  jz   R0, 0x0A      ; if R0 == 0, end delay
9:  jump 0x07          ; otherwise repeat delay loop

10: andi R0, R5, 0x01  ; check SW0
11: jz   R0, 0x0A      ; if SW0 == 0, wait

12: movi R4, 0x04      ; turn on LED2
13: movi R0, 0xF0      ; initialize delay counter

14: addi R0, R0, 0x01  ; increment delay counter
15: jz   R0, 0x11      ; if R0 == 0, end delay
16: jump 0x0E          ; otherwise repeat delay loop

17: movi R4, 0x08      ; turn on LED3
18: movi R0, 0xF0      ; initialize delay counter

19: addi R0, R0, 0x01  ; increment delay counter
20: jz   R0, 0x16      ; if R0 == 0, end delay
21: jump 0x13          ; otherwise repeat delay loop

22: andi R0, R5, 0x02  ; check SW1
23: jz   R0, 0x16      ; if SW1 == 0, wait

24: jump 0x00          ; return to the beginning
```

## Program behavior

The program performs the following sequence:

```text
LED0 on for approximately 1 second
LED1 on for approximately 1 second
wait for SW0
LED2 on for approximately 1 second
LED3 on for approximately 1 second
wait for SW1
return to LED0
```

The LED values are:

| Value written to `R4` | Binary value | Active LED |
| --------------------- | ------------ | ---------- |
| `0x01`                | `00000001`   | LED0       |
| `0x02`                | `00000010`   | LED1       |
| `0x04`                | `00000100`   | LED2       |
| `0x08`                | `00001000`   | LED3       |

The switch masks are:

| Mask   | Binary value | Checked switch |
| ------ | ------------ | -------------- |
| `0x01` | `00000001`   | SW0            |
| `0x02` | `00000010`   | SW1            |

## Delay loop explanation

The processor is clocked at 50 Hz in the FPGA top-level module. This means that one processor instruction is executed approximately every:

```text
1 / 50 Hz = 0.02 s = 20 ms
```

To keep each LED on for about one second, the program uses a delay loop.

The delay counter is initialized as:

```asm
movi R0, 0xF0
```

`0xF0` is decimal `240`.

Since `R0` is an 8-bit register, it overflows after `255` back to `0`:

```text
240 -> 241 -> 242 -> ... -> 254 -> 255 -> 0
```

The loop checks when `R0` becomes zero:

```asm
addi R0, R0, 0x01
jz   R0, next_instruction
jump loop_start
```

This creates approximately 16 loop iterations. Each iteration takes about 3 instructions, so the delay is approximately:

```text
16 * 3 * 20 ms = 960 ms
```

Including setup and branch instructions, this gives roughly one second of visible LED time.

## FPGA top module

The `top.v` file connects the processor to the FPGA board.

The top-level ports are:

```verilog
module top
(
    input clk,
    input [3:0] sw,
    output [3:0] led
);
```

The board clock is divided down to a slower clock used by the processor.

For a 125 MHz input clock, the divider toggles `slow_clk` every 1,250,000 input clock cycles:

```verilog
if (counter == 21'd1_249_999) begin
    counter <= 21'd0;
    slow_clk <= ~slow_clk;
end
```

This produces a `50 Hz` processor clock:

```text
125 MHz / (2 * 1,250,000) = 50 Hz
```

The switches are connected to the lower 4 bits of the 8-bit processor input:

```verilog
assign gpi = {4'b0000, sw};
```

The lower 4 bits of the processor output are connected to the LEDs:

```verilog
assign led = gpo[3:0];
```

## Data memory

The `d_mem.v` file contains a very small example data memory:

```verilog
assign data_memory[0]=8'b00000001;
assign data_memory[1]=8'b00000010;
```

The current LED/switch program does not rely on data memory. It mainly uses the ALU result as the writeback source.

The data memory remains in the processor architecture to demonstrate how memory access could be integrated.

## Simulation

The project contains two simulation testbenches.

### `tb_13_2.v`

This testbench verifies basic processor operation.

It overrides selected instruction memory entries using `force`:

```verilog
force uut.instruction_memory.program[0] = 32'h00168005; // movi r0, 5
force uut.instruction_memory.program[1] = 32'h00106100; // mov r1, r0
force uut.instruction_memory.program[2] = 32'h01368602; // jump 2
```

The simulated program is:

```asm
0: movi R0, 5
1: mov  R1, R0
2: jump 2
```

Expected result:

```text
R0 = 5
R1 = 5
```

If the values are correct, the testbench prints:

```text
TEST 13.2 OK
```

### `tb_processor.v`

This testbench verifies the main LED/switch program from `i_mem.v`.

It simulates:

* clock signal,
* switch input through `gpi`,
* LED output through `gpo`.

The input changes are:

```verilog
gpi = 8'b00000000;
#500;

gpi = 8'b00000001;
#400;

gpi = 8'b00000011;
#600;
```

This simulates:

```text
SW0 = 0, SW1 = 0
then SW0 = 1
then SW0 = 1, SW1 = 1
```

Expected output behavior:

```text
gpo = 0x01
gpo = 0x02
wait until SW0 is enabled
gpo = 0x04
gpo = 0x08
wait until SW1 is enabled
return to gpo = 0x01
```

## How to recreate the project in Vivado

A typical reconstruction flow is:

1. Create a new RTL project in Xilinx Vivado.
2. Add source files from the `src/` directory:

   * `processor.v`,
   * `i_mem.v`,
   * `d_mem.v`,
   * `top.v`.
3. Add simulation files from the `sim/` directory:

   * `tb_processor.v`,
   * `tb_13_2.v`.
4. Add the constraint file from `constraints/`, for example:

   * `ZYBO_Master.xdc`.
5. For simulation:

   * set `tb_processor.v` or `tb_13_2.v` as the simulation top module,
   * run behavioral simulation.
6. For FPGA implementation:

   * set `top.v` as the top module,
   * run synthesis,
   * run implementation,
   * generate bitstream,
   * program the FPGA board.

## What this project demonstrates

This project demonstrates:

* basic processor architecture,
* instruction decoding,
* register-based datapath,
* ALU design,
* operand multiplexers,
* program counter control,
* conditional and unconditional jumps,
* instruction memory,
* simple data memory,
* memory-mapped style I/O concept,
* FPGA top-level integration,
* clock division,
* Verilog testbenches,
* behavioral simulation in Vivado,
* FPGA implementation flow.

## Notes

This repository contains selected source files and testbenches. Generated Vivado folders such as `.runs`, `.sim`, `.cache`, `.Xil` and temporary log files are intentionally not included.

The project is primarily intended as a documented laboratory implementation and a compact portfolio example of a simple soft processor in Verilog.
