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
    end else if (measure_in) begin
        if ($signed(delta_t) > $signed(threshold)) begin
            if (y_diff == 0) begin
                change_out <= 0;
            end else if (($signed(y_diff) > 0 && $signed(prev_y_diff) < 0) || ($signed(y_diff) < 0 && $signed(prev_y_diff) > 0)) begin
                change_out <= 1;
                prev_y_in <= y_in;
                prev_y_diff <= y_diff;  
            end else begin
                change_out <= 0;
                prev_y_in <= y_in;
                prev_y_diff <= y_diff;  
            end
        end
        delta_t <= (($signed(y_diff) > 0 && $signed(prev_y_diff) < 0) || ($signed(y_diff) < 0 && $signed(prev_y_diff) > 0))? 0: delta_t + 1; // if change in sign, reset
       
        
        // implementation of the derivative algorithm
        // prev_y_in <= y_in;
        // prev_y_diff <= y_diff;
        // // if the old derivative 
        // // wait something like 10k clock cycles to allow the noise to average itself out
        // if (delta_t > threshold) begin
        //     if ((prev_y_diff > 0)) begin // if signs are different, change_out is high
        //         change_out <= 1; 
        //         delta_t <= 0;
        //     end else begin
        //         change_out <= 0;
        //         delta_t <= delta_t + 1;
        //     end
        // end

    end
end
endmodule
`default_nettype wire
