`timescale 1ns / 1ps
`default_nettype none

module uart_transmit 
  #(
    parameter INPUT_CLOCK_FREQ = 100_000_000,
    parameter BAUD_RATE = 9600
    )
   (
    input wire 	     clk_in,
    input wire 	     rst_in,
    input wire [7:0] data_byte_in,
    input wire 	     trigger_in,
    output logic     busy_out,
    output logic     tx_wire_out
    );

  localparam DATA_WIDTH = 9; // including the end bit
  localparam CYCLE_PER_BIT = INPUT_CLOCK_FREQ/BAUD_RATE;
  localparam COUNTER_SIZE = $clog2(CYCLE_PER_BIT);
  logic [8:0] buffer_in;
  logic [COUNTER_SIZE:0] cycle_counter;
  logic [3:0] byte_counter;
   
  always_ff @(posedge clk_in) begin
    if (rst_in) begin // set all outputs to 0?
      busy_out <= 0;
      tx_wire_out <= 1;
    end else if (~busy_out) begin
      if (trigger_in) begin
        busy_out <= 1;
        tx_wire_out <= 0;
        buffer_in <= {1'b1, data_byte_in};
        byte_counter <= 0;
        cycle_counter <= 0;
      end else begin
        tx_wire_out <= 1;
      end
    end else if (busy_out) begin
      if (cycle_counter == CYCLE_PER_BIT - 1) begin
        cycle_counter <= 0;
        if (byte_counter == 9) begin
          busy_out <= (trigger_in)? 1: 0;
          byte_counter <= 0;
          cycle_counter <= 0;
          buffer_in <= (trigger_in)? {1'b1, data_byte_in}: 0;
          tx_wire_out <= (trigger_in)? 0: 1;
        end else begin
          tx_wire_out <= buffer_in[0];
          buffer_in <= buffer_in >> 1;
          byte_counter <= byte_counter + 1'b1;
        end
      end else begin
        cycle_counter <= cycle_counter + 1;
      end
    end
  end
   
endmodule // uart_transmit

`default_nettype wire
