module parity (
  input clk,
  input reset,
  input in,
  output reg odd);

  always @(posedge clk)
    if (reset) odd <= 0;
    else if (in) odd <= ~odd;
endmodule

module uart_rx (
  input clk,
  input reset,
  input rx,

  output reg [7:0] data_out,
  output reg data_valid,
  output busy,
  output reg parity_error
);
  parameter clk_freq= 16_000_000; // 16 MHz
  parameter baud_rate = 9600;

  // ------------16x oversampling generator------------
  localparam OVERSAMPLE = 16;
  localparam clks_per_oversample_tick = clk_freq / (baud_rate * OVERSAMPLE);

  localparam width = $clog2(clks_per_oversample_tick); // Calculate the number of bits

  reg [width-1:0] clk_count;
  reg oversample_tick;

  always @(posedge clk) begin
    if (reset) begin
      clk_count <= 0;
      oversample_tick <= 0;
    end 
    else if (clk_count == clks_per_oversample_tick - 1) begin
      clk_count <= 0;
      oversample_tick <= 1;
    end 
    else begin
      clk_count <= clk_count + 1;
      oversample_tick <= 0;
    end
  end

  // ------------2 Flop synchroniser for rx input-----------
  reg [1:0] rx_sync;
  always @(posedge clk) begin
    if (reset) rx_sync <= 2'b11; // Idle state is high
    else rx_sync <= {rx_sync[0], rx};
  end
  // read rx_sync[1] for stable rx value

  // ------------State machine for receiving data-----------
  reg [3:0] tick_count; // To count oversample ticks (0 - 15)
  reg [2:0] bit_count; // To count data bits received 0 - 7 (excluding parity)
  reg [7:0] rx_data; // To store received data bits
  reg [2:0] state, next;

  wire odd; 
  wire reset_parity = (state == idle) || (state == recovery);
  wire parity_in = (state == data && tick_count == 15 && oversample_tick) ? rx_sync[1] : 1'b0;

  parity parity_gen (
    .clk(clk),
    .reset(reset_parity),
    .in(parity_in),
    .odd(odd)
  );

  localparam idle=0, start=1, data=2, parity=3, stop=4, recovery=5;

  // --- Next State Logic ---
  always @(*) begin
    case(state)
      idle: next = (rx_sync[1] == 0) ? start : idle;
      start: next = (tick_count == 7) ? ((rx_sync[1] == 0) ? data : idle) : start;
      data: next = (bit_count == 7 && tick_count == 15) ? parity : data;
      parity: next = (tick_count == 15) ? stop : parity;
      stop: next = (tick_count == 15) ? ((rx_sync[1] == 1) ? idle : recovery) : stop;
      recovery: next = (rx_sync[1] == 1) ? idle : recovery;
      default: next = idle;
    endcase
  end

  always @(posedge clk) begin
    if (reset) begin
      state <= idle;
      tick_count <= 4'b0000;
      bit_count <= 3'b000;
      rx_data <= 8'b00000000;
      data_out <= 8'b00000000;
      data_valid <= 1'b0;
      parity_error <= 1'b0;
    end 
    else begin
      if (oversample_tick) begin
        state <= next;
        data_valid <= 1'b0;
        
        if (state == idle) begin
          tick_count <= 0;
          parity_error <= 1'b0;
        end
        else if ((state != next) || (tick_count == 15))
          tick_count <= 0;
        else
          tick_count <= tick_count + 1;

        if (state == start && next == data)
          bit_count <= 0; // Reset bit count at the end of start bit
        
        if (state == data && tick_count == 15) begin
          rx_data[bit_count] <= rx_sync[1];
          bit_count <= bit_count + 1;
        end

        if (state == parity && tick_count == 15) begin
          parity_error <= (rx_sync[1] == odd);
        end

        if (state == stop && tick_count == 15) begin
          if (rx_sync[1] == 1) begin
            data_out <= rx_data;
            if (parity_error) data_valid <= 1'b0;
            else data_valid <= 1'b1;
          end
        end
      end
    end
  end

  assign busy = (state != idle);
endmodule