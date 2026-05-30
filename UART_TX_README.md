# UART Transmitter (UART TX) in Verilog

## Overview

This project implements a parameterized UART (Universal Asynchronous Receiver Transmitter) transmitter in Verilog HDL.

The transmitter sends serial data using the standard UART frame format:

* 1 Start Bit
* 8 Data Bits
* 1 Odd Parity Bit (8O1)
* 1 Stop Bit

The design is fully synchronous and uses a baud-rate tick generator derived from the FPGA system clock.

---

# Features

* Parameterized clock frequency and baud rate
* FSM-based UART transmission
* Internal baud tick generator
* Busy signal during active transmission
* Done pulse after frame completion
* LSB-first transmission
* Modular and synthesizable RTL
* Compatible with FPGA workflows and simulators like:
  * Icarus Verilog
  * GTKWave
  * Vivado

---

# UART Frame Format

UART transmission format used in this project:

| Bit Type  | Value              |
| --------- | ------------------ |
| Idle      | 1                  |
| Start Bit | 0                  |
| Data Bits | 8 bits (LSB first) |
| Parity Bit| Odd                |
| Stop Bit  | 1                  |

Example transmission for `8'hA3`:

```text
Idle(1) -> Start(0) -> 1 -> 1 -> 0 -> 0 -> 0 -> 1 -> 0 -> 1 -> Parity(1) -> Stop(1)
```

---

# Module Interface

## Inputs

### `clk`

System clock input.

### `reset`

Synchronous active-high reset.

### `tx_start`

Starts transmission of `data_in`.

### `data_in[7:0]`

8-bit parallel data to transmit.

---

## Outputs

### `tx`

UART serial transmit line.

### `busy`

High while transmission is in progress.

### `done`

Pulses high for one clock cycle after successful frame completion.

---

# Internal Architecture

The design consists of two major blocks:

## 1. Baud Tick Generator

The baud generator divides the high-frequency FPGA clock into baud-rate timing pulses.

Example:

```text
16 MHz clock -> 9600 baud timing
```

A single-cycle `baud_tick` pulse is generated periodically and used to advance UART transmission timing.

---

## 2. UART TX FSM

The transmitter is controlled using a finite state machine.

### States

| State | Function                      |
| ----- | ----------------------------- |
| IDLE  | Wait for transmission request |
| START | Send start bit                |
| DATA  | Send 8 data bits              |
| PARITY| Send odd parity bit           |
| STOP  | Send stop bit                 |

The FSM transitions only on baud ticks.

---

# Design Decisions

## Parameterization

The module uses:

```verilog
parameter clk_freq
parameter baud_rate
```

This allows the same RTL to work across different FPGA clock frequencies and UART baud rates without modifying the design logic.

---

## LSB-First Transmission

UART protocol transmits the least significant bit first.

Example:

```text
0xA3 = 10100011
Transmission order:
1 -> 1 -> 0 -> 0 -> 0 -> 1 -> 0 -> 1
```

---

# Simulation

The design was simulated using:

* Icarus Verilog
* GTKWave

Waveforms were verified for:

* Correct baud timing
* Proper start/stop bit generation
* Correct serial bit ordering
* Busy signal behavior
* Done pulse timing

## How to connect it (Ports)

**Inputs:**

* `clk`: Your main system clock.
* `reset`: Synchronous active-high reset.
* `tx_start`: Pulse this high for one clock cycle to tell the module, "Send the data"
* `data_in [7:0]`: The 8-bit byte you want to transmit.

**Outputs:**

* `tx`: The actual outgoing serial data wire.
* `busy`: High while it is actively sending a frame. Use this to tell your other modules to hold off on sending new data!
* `done`: Pulses high for exactly **one clock cycle** when the STOP bit is successfully completed.

## Copy-Paste Template

Use this to easily drop the module into your top-level design:

```verilog
uart_tx #(
    .clk_freq(100_000_000), // Change this to your board's clock speed
    .baud_rate(9600)        // Change this to your desired baud rate
) my_transmitter (
    .clk(clk),
    .reset(reset),
    .tx_start(send_signal),
    .data_in(byte_to_send),
    
    .tx(tx_pin),
    .busy(tx_is_busy),
    .done(tx_is_done)
);

```

# Learning Goals of This Project

This project was built to understand:

* FSM design in RTL
* Clock division and timing generation
* Serial communication protocols
* Synchronization between datapath and control path
* Hardware-oriented thinking in Verilog
* Simulation and waveform debugging