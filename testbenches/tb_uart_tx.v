`timescale 1ns / 1ps
module tb_uart_tx();
  reg clk;
  reg reset;
  reg tx_start;
  reg [7:0] data_in;
  
  wire tx;
  wire busy;
  wire done;

  top_module #(
    .clk_freq(100_000), 
    .baud_rate(10_000)
  ) uut (
    .clk(clk),
    .reset(reset),
    .tx_start(tx_start),
    .data_in(data_in),
    .tx(tx),
    .busy(busy),
    .done(done)
  );

  // 100MHz clock generation
  always #5 clk = ~clk;

  initial begin
    // GTKWave dump
    $dumpfile("wave.vcd");
    $dumpvars(0, tb_uart_tx);
    // initial setup and reset
    clk = 0;
    reset = 1;
    tx_start = 0;
    data_in = 8'h00;

    #20 reset = 0;
    #20;

    // Test 1: Send 8'hA5 (10100101)
    // 4 ones -> odd parity bit should be 1
    $display("[%0t] Sending A5", $time);
    @(posedge clk);
    data_in = 8'hA5;
    tx_start = 1;
    @(posedge clk);
    tx_start = 0; // 1-cycle pulse

    @(posedge done);
    #50;

    // Test 2: Data latching and ignoring random start pulses
    // Sending 8'h3C (00111100) -> 4 ones -> parity 1
    $display("[%0t] Sending 3C and trying to interrupt it", $time);
    @(posedge clk);
    data_in = 8'h3C;
    tx_start = 1;
    @(posedge clk);
    tx_start = 0;
    
    data_in = 8'hFF; // try to corrupt the data line right after start
    
    // wait a bit and try to restart it while it's busy
    #500; 
    @(posedge clk);
    tx_start = 1;
    @(posedge clk);
    tx_start = 0;

    @(posedge done);

    // Test 3: Send 8'h07 (00000111) back-to-back
    // 3 ones -> odd parity bit should be 0 this time
    $display("[%0t] Sending 07 back-to-back", $time);
    @(posedge clk);
    data_in = 8'h07;
    tx_start = 1;
    @(posedge clk);
    tx_start = 0;
    
    @(posedge done);

    #100;
    $display("[%0t] All tests finished", $time);
    $finish;
  end
endmodule