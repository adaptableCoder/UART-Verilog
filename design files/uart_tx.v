// 8O1 uart tx -> 8 data bits, Odd parity, 1 stop bit
module uart_tx (
  input clk,
  input reset,
  input tx_start,
  input [7:0] data_in,
  output reg tx,
  output busy,
  output reg done
);
  parameter clk_freq = 16_000_000; // 16 MHz
  parameter baud_rate = 9600;

  // -------------- Baud tick generator --------------
  localparam clks_per_bit = clk_freq / baud_rate;

  localparam width = $clog2(clks_per_bit); // Calculate the number of bits needed for the counter
  reg [width-1:0] clk_count;
  reg baud_tick;

  always @(posedge clk) begin
    if (reset || !busy) begin
      clk_count <= 0;
      baud_tick <= 0;
    end 
    else if (clk_count == clks_per_bit - 1) begin
      clk_count <= 0;
      baud_tick <= 1;
    end 
    else begin
      clk_count <= clk_count + 1;
      baud_tick <= 0;
    end
  end

  // ------------TX logic------------
  localparam IDLE = 0, START = 1, DATA = 2, STOP = 3;
  reg [1:0] state, next_state;
  reg [3:0] baud_tick_count; // To count the number of bits transmitted (0-8)
  reg [8:0] tx_data; // Internal Register to hold the data being transmitted + parity bit

  // Control path for state transitions
  always @(*) begin
    case (state)
      IDLE: next_state = tx_start ? START : IDLE;
      START: next_state = DATA;
      DATA: next_state = (baud_tick_count == 8) ? STOP : DATA; // After 9 bits, go to STOP
      STOP: next_state = IDLE;
      default: next_state = IDLE;
    endcase
  end

  // Sequential logic for state transitions
  always @(posedge clk) begin
    if (reset) begin
      state <= IDLE;
      baud_tick_count <= 0;
      done <= 1'b0;
      tx_data <= 9'b000000000;
    end
    else begin
      if ((state == IDLE && tx_start) || (state != IDLE && baud_tick)) begin
        state <= next_state;

        if (state == IDLE)
          tx_data <= {~^data_in, data_in}; // Load data into tx_data at the start of transmission
          // data at [7:0] and parity bit at [8]
          //using ODD parity because Odd Parity is slightly safer: If a line gets disconnected or stuck at logic low (00000000), even parity stays 0, which looks valid. Odd parity forces a 1, flagging the dead line as an error.
          // using reduction XNOR operator to calculate parity bit.

        if (state==DATA)
          baud_tick_count <= baud_tick_count + 1;
        else 
          baud_tick_count <= 0;
      end
    end

    if (state == STOP && next_state == IDLE && baud_tick)
      done <= 1; // Signal that transmission is done
    else
      done <= 0;

  end

  // Data path for TX output
  always @(*) begin
    case (state)
      IDLE: tx = 1;                         // Idle state, line is high
      START: tx = 0;                        // Start bit, line goes low
      DATA: tx = tx_data[baud_tick_count];  // Transmit serially
      STOP: tx = 1;                         // Stop bit, line goes high
      default: tx = 1;
    endcase
  end

  assign busy = (state != IDLE);
endmodule