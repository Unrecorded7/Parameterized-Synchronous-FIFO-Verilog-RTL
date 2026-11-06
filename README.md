# Parameterized Synchronous FIFO — Verilog RTL

A parameterized synchronous FIFO (First-In First-Out) designed using Verilog HDL. The design supports configurable data width and FIFO depth, including **non-power-of-2 depths**.

## Overview

This project implements a synchronous FIFO with independent read and write control logic, pointer-based memory addressing, and full/empty status detection.

Unlike conventional FIFO implementations that rely on natural binary pointer overflow, this design uses explicit pointer wrapping to support arbitrary valid FIFO depths.

## Features

- Parameterized data width (`WIDTH`).
- Parameterized FIFO depth (`DEPTH`).
- Supports non-power-of-2 depths.
- Independent read and write pointers.
- Extra MSB for wraparound detection.
- Full and empty flag generation.
- Simultaneous read/write support.
- Synchronous active-high reset.
- Self-checking testbench with a reference FIFO model.
- Directed and randomized verification.

## Architecture

### 1. FIFO Memory

The FIFO storage is implemented using a Verilog register array:

```verilog
reg [WIDTH-1:0] q [0:DEPTH-1];
```

### 2. Pointer Management

Two pointers are maintained:

- `ptr_w`: Points to the next write location.
- `ptr_r`: Points to the next read location.

An additional MSB is included in both pointers to distinguish between different memory traversal cycles.

```verilog
reg [PTR_WIDTH:0] ptr_r, ptr_w;
```

The pointer width is calculated using:

```verilog
localparam PTR_WIDTH = (DEPTH <= 1) ? 1 : $clog2(DEPTH);
```

### 3. Non-Power-of-2 Support

For non-power-of-2 FIFO depths, natural binary overflow cannot be used because it may generate invalid memory addresses.

Therefore, explicit wraparound logic is implemented.

When a pointer reaches `DEPTH-1`:

- Its lower bits are reset to zero.
- Its extra MSB is toggled.

This ensures correct circular buffer operation for depths such as 3, 5, 7, and 10.

### 4. Full and Empty Detection

**Empty condition:**

The FIFO is empty when both read and write pointers are identical.

```verilog
assign empty = (ptr_r == ptr_w);
```

**Full condition:**

The FIFO is full when the lower pointer bits are equal but their wraparound bits differ.

```verilog
assign wrap_around = ptr_w[PTR_WIDTH] ^ ptr_r[PTR_WIDTH];

assign full = wrap_around &&
              (ptr_r[PTR_WIDTH-1:0] == ptr_w[PTR_WIDTH-1:0]);
```

## Parameters

| Parameter | Default | Description                  |
| --------- | ------: | ---------------------------- |
| WIDTH     |       8 | Number of bits per data word |
| DEPTH     |      10 | Number of FIFO entries       |

Example configuration:

```verilog
fifo #(
    .WIDTH(8),
    .DEPTH(10)
) dut (
    // Port connections
);
```

## Interface

| Signal     | Direction | Description                   |
| ---------- | --------- | ----------------------------- |
| `clk`      | Input     | Clock                         |
| `rst`      | Input     | Synchronous active-high reset |
| `w_en`     | Input     | Write enable                  |
| `r_en`     | Input     | Read enable                   |
| `data_in`  | Input     | Input data                    |
| `data_out` | Output    | Read data                     |
| `full`     | Output    | FIFO full indicator           |
| `empty`    | Output    | FIFO empty indicator          |

## Verification

The design was verified using Icarus Verilog with a self-checking testbench.

The testbench maintains an independent reference FIFO model using `head`, `tail`, and `count` to verify data ordering and FIFO status flags.

### Test Scenarios

| Test             | Description                        |
| ---------------- | ---------------------------------- |
| Reset            | Verify initial FIFO state          |
| Fill             | Write until FIFO becomes full      |
| Overflow         | Attempt writing when full          |
| Simultaneous R/W | Read and write when full           |
| Drain            | Read until FIFO becomes empty      |
| Underflow        | Attempt reading when empty         |
| Empty R/W        | Simultaneous read/write when empty |
| Random Testing   | 500 randomized transactions        |

**Simulation configuration:**

- Data width: 8 bits
- FIFO depth: 10 entries
- Randomized transactions: 500

**Simulation result:** All directed and randomized tests passed.

## Tools Used

- Verilog HDL
- Icarus Verilog — Simulation
- GTKWave — Waveform Analysis
- VS Code — Development Environment

## Running the Simulation

Compile the RTL and testbench:

```bash
iverilog -g2012 -o sim.out FIFO.v FIFO_tb.v
```

Run the simulation:

```bash
vvp sim.out
```

Open the generated waveform:

```bash
gtkwave FIFO.vcd
```

## Project Structure

```text
FIFO/
│
├── FIFO.v
├── FIFO_tb.v
├── FIFO.vcd
└── README.md
```

## Learning Outcomes

Through this project, I explored:

- Circular buffer implementation using read/write pointers.
- Pointer wraparound and extra-MSB logic.
- FIFO full and empty detection.
- Handling simultaneous read/write operations.
- Parameterized RTL design.
- Self-checking testbench development and reference-model verification.

---

