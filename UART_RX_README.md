# UART Receiver (UART RX) in Verilog

## What is this?
This is a robust Verilog module that receives serial data (UART). It listens to a single wire (`rx`), reads the incoming 1s and 0s, and packages them into clean 8-bit bytes.

Because the real world is noisy, this module doesn't just blindly read the wire. It uses **16x oversampling**. This means it chops every incoming bit into 16 tiny time slices so it can sample the data right in the exact dead-center of the bit. This ignores glitches and keeps the data perfectly synced.

## Special Features

- **Strict Error Protection:** If a byte gets corrupted by noise on the wire, the module calculates the math, realizes it's wrong, flags a `parity_error`, and **refuses** to pulse the `data_valid` signal. This acts like a brick wall, protecting the rest of your system from reading garbage data.
- **Odd Parity Checking:** It expects 8 data bits followed by an odd parity bit.
- **Framing Error Recovery:** If a sender messes up and forgets to send a STOP bit (the line stays low when it should be high), this module won't read a fake start bit. It goes into a safe "Recovery" state until the line goes back to idle.
- **Parameter-Driven:** Uses clk_freq and baud_rate parameters to automatically calculate the 16x oversampling math for any FPGA.
- **Toolchain Proven:** Verified in simulation using Icarus Verilog and GTKWave.

## How the State Machine Works

The brain of this module moves through 6 simple steps:

1. **Idle:** The Rx line is normally HIGH when no data is incoming, this state waits for it to drop to `0`.
2. **Start:** The Rx line went LOW, but is it real, or just noise? It waits until the middle of the start bit. If it's still `0`, it's a real transmission.
3. **Data:** Reads the next 8 bits one by one, grabbing them exactly in the middle of their time slots.
4. **Parity:** Reads the 9th bit and checks if it matches the calculated odd parity math.
5. **Stop:** Looks for the final `1`. If everything (including parity) is perfect, it pulses `data_valid` to tell your system the byte is ready. If not then it sets `parity_error`. If the stop bit is missing, it jumps to Recovery.
6. **Recovery:** The line is stuck low. It hangs out here until the wire goes back to a safe high `1` state so it's ready for the next package.

## How to connect it (Ports)

**Inputs:**

* `clk`: Your main system clock.
* `reset`: Synchronous reset. Pulse it high to clear everything and start fresh.
* `rx`: The actual incoming serial data wire.

**Outputs:**

* `data_out [7:0]`: The final 8-bit received byte.
* `data_valid`: Pulses high for exactly **one clock cycle** when a perfect, error-free byte is ready to be read.
* `busy`: High whenever the module is actively receiving a byte.
* `parity_error`: Goes high if the incoming data got corrupted. (Note: `data_valid` will stay low if this happens).

## Copy-Paste Template

Use this to easily drop the module into your top-level design:

```verilog
uart_rx #(
    .clk_freq(100_000_000), // Change this to your board's clock speed
    .baud_rate(9600)        // Change this to your desired baud rate
) my_receiver (
    .clk(clk),
    .reset(reset),
    .rx(rx_pin),
    
    .data_out(received_byte),
    .data_valid(byte_is_ready),
    .busy(rx_is_busy),
    .parity_error(rx_error_flag)
);

```