`timescale 1ns / 1ps
`default_nettype none

module sine_machine(
        input wire clk_in,
        input wire rst_in,
        input wire midi_burst_ready_in,
        input wire [2:0] on_msg_count_in,
        input logic [31:0] midi_burst_data_in [4:0],
        output logic pwm_ready,
        output logic sig_out);

    

endmodule

`default_nettype wire