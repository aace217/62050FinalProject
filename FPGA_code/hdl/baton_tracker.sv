`timescale 1ns / 1ps
`default_nettype none

module baton_tracker(
    input wire [9:0] y_in,
    input wire measure_in,
    input wire rst_in,
    input wire clk_camera_in,
    output logic change_out
);
logic signed [9:0] prev_y_diff;
logic [18:0] delta_t; // counter for making sure that data is valid
logic signed [9:0] y_diff;
logic signed [9:0] prev_y_in;

logic signed [18:0] threshold; // threshold for making sure that data is valid
// assign threshold = ;

assign threshold = -1;
assign y_diff = $signed(y_in) - $signed(prev_y_in); 

always_ff @(posedge clk_camera_in) begin
    if (rst_in) begin
        // reset all the variables
        change_out <= 0;
        prev_y_diff <= 0;
        prev_y_in <= 0;
        delta_t <= 0;
        // stage <= 0;
    end else if (measure_in) begin
        if ($signed(delta_t) > $signed(threshold)) begin
            if ($signed(y_diff) >= -2 && $signed(y_diff) <= 2) begin
                change_out <= 0;
                // stage <= 4'b0111;
                // prev_y_diff <= y_diff;
            end else if (($signed(y_diff) < -2 && $signed(prev_y_diff) > 2)) begin //  || ($signed(y_diff) > 5 && $signed(prev_y_diff) < 5)
                change_out <= 1;
                prev_y_in <= y_in;
                prev_y_diff <= y_diff;  
                // stage <= 4'b1111;
            end else begin
                change_out <= 0;
                prev_y_in <= y_in;
                prev_y_diff <= y_diff;  
                // stage <= 4'b1010;
            end
        end
        delta_t <= (($signed(y_diff) < -2 && $signed(prev_y_diff) > 2))? 0: delta_t + 1; // if change in sign, reset
    end
end
endmodule
`default_nettype wire
