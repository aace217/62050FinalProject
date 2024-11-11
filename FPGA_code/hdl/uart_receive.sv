`timescale 1ns / 1ps
`default_nettype none

module uart_receive
  #(
    parameter INPUT_CLOCK_FREQ = 100_000_000,
    parameter BAUD_RATE = 9600
    )
   (
    input wire 	       clk_in,
    input wire 	       rst_in,
    input wire 	       rx_wire_in,
    output logic       new_data_out,
    output logic [7:0] data_byte_out
    );
    
    localparam UART_BIT_PERIOD = INPUT_CLOCK_FREQ/BAUD_RATE;
    localparam HALF_PERIOD = (UART_BIT_PERIOD/2);
    localparam QUARTER_PERIOD = (3*UART_BIT_PERIOD/4);
    logic [7:0] buffer_byte; 
    logic [$clog2(UART_BIT_PERIOD)-1:0] bit_cycles;
    logic [7:0] bit_count;
    logic past_half;

    enum logic [2:0] {IDLE,START,DATA,TRANSMIT,STOP} receive_state;

   always_ff @(posedge clk_in)begin
        if(rst_in)begin
            receive_state <= IDLE;
            bit_count <= 0;
            data_byte_out <= 0;
            buffer_byte <= 0;
            bit_cycles <= 0;
        end else begin
            case(receive_state)
                IDLE: begin
                        past_half <= 0;
                        bit_cycles <= 0;
                        buffer_byte <= 0;
                        new_data_out <= 0;
                        if(~rx_wire_in)begin
                            receive_state <= START;
                        end
                end
                START: begin
                    if(~rx_wire_in) begin
                        if(bit_cycles == HALF_PERIOD-1)begin
                            receive_state <= DATA;
                        end
                        bit_cycles <= bit_cycles +1;
                    end else begin
                        bit_cycles <= 0;
                        receive_state <= IDLE;
                    end
                end
                DATA: begin
                    if((bit_count == 8) && (bit_cycles == UART_BIT_PERIOD -1))begin
                        receive_state <= STOP;
                        bit_count <= 0;
                        bit_cycles <= 0;
                    end else if (bit_cycles == HALF_PERIOD-1) begin
                        bit_cycles <= bit_cycles + 1;
                        //buffer_byte[bit_count] <= rx_wire_in;
                        buffer_byte <= {rx_wire_in,buffer_byte[7:1]};
                        bit_count <= bit_count + 1;
                    end else begin
                        bit_cycles <= (bit_cycles==UART_BIT_PERIOD-1)?0:bit_cycles+1;
                    end
                end
                TRANSMIT: begin
                    new_data_out <= 1;
                    receive_state <= IDLE;
                    data_byte_out <= buffer_byte;
                end
                STOP: begin
                    if((bit_cycles>HALF_PERIOD-1))begin
                        past_half <= 1;
                        if (bit_count == UART_BIT_PERIOD-1) begin
                            receive_state <= IDLE;
                            bit_cycles <= 0;
                            past_half <= 0;
                        end
                        else if(bit_cycles == QUARTER_PERIOD)begin
                            bit_cycles <= 0;
                            receive_state <= TRANSMIT;
                        end else if (~rx_wire_in) begin
                            bit_cycles <= 0;
                            past_half <= 0;
                            receive_state <= IDLE;
                        end
                    end else begin
                        past_half <= 0;
                    end
                    bit_cycles <= bit_cycles + 1;
                end
                default: receive_state <= IDLE;
            endcase
        end
   end

endmodule // uart_receive

`default_nettype wire