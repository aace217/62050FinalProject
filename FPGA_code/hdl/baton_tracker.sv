`timescale 1ns / 1ps
`default_nettype none

module baton_tracker(
    input wire [9:0] y_com_in,
    input wire measure_in,
    input wire rst_in,
    input wire clk_camera_in,
    output logic change_out
);
logic signed [9:0] current_derivative;
logic signed [9:0] old_derivative;
logic [18:0] delta_t; // counter for making sure that data is valid
logic signed [10:0] y_diff;
logic signed [9:0] old_y;

assign y_diff = y_com_in - $signed(old_y); 

always_ff @(posedge clk_camera_in) begin
    if(rst_in)begin
        // reset all the variables
        change_out <= 0;
        current_derivative <= 0;
        old_y <= 0;
        delta_t <= 0;
    end else begin
        // implementation of the derivative algorithm
        old_y <= y_com_in;
        old_derivative <= current_derivative;
        // if the old derivative 
        // wait something like 10k clock cycles to allow the noise to average itself out
        if()begin

        end

    end
end
endmodule
`default_nettype wire
