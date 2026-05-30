`timescale 1ns / 1ps

module tb;

  reg clk;
  reg reset;

  wire tx;
  wire busy;
  wire done;

  // DUT
  top_module #(
    .clk_freq(16),
    .baud_rate(4)
  ) uut (
    .clk(clk),
    .reset(reset),
    .tx_start(1'b0),   // unused for now
    .data_in(8'h00),   // unused for now
    .tx(tx),
    .busy(busy),
    .done(done)
  );

  // Clock generation
  always #5 clk = ~clk;

  initial begin
    // GTKWave dump
    $dumpfile("wave.vcd");
    $dumpvars(0, tb);

    // Initial values
    clk = 0;
    reset = 1;

    // Hold reset for a few cycles
    #20;
    reset = 0;

    // Run simulation long enough to observe baud ticks
    #200;

    $finish;
  end

endmodule