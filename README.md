# UART in Verilog

This project implements a UART (Universal Asynchronous Receiver/Transmitter) transmitter and receiver in Verilog. 

- **Design Files**: Located in `design files/` (`uart_tx.v` and `uart_rx.v`).
- **Testbenches**: Located in `testbenches/` (`tb_uart_tx.v` and `tb_baud_gen.v`).

## Simulation

To run the testbenches, you need Icarus Verilog and GTKWave installed.

Use the following commands as an example:
```bash
iverilog -o sim "design files/uart_tx.v" "testbenches/tb_uart_tx.v"
vvp sim
gtkwave wave.vcd
```

## GTKWave Waveform (Tx Only)

This waveform demonstrates the simulation output for the UART transmitter module only.

![UART TX Waveform](images/UART_TX_Waveform.png)

## Documentation

For detailed information on the modules, see:
- [UART Transmitter README](UART_TX_README.md)
- [UART Receiver README](UART_RX_README.md)