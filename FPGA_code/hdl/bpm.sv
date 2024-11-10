`timescale 1ns / 1ps
`default_nettype none

module bpm(
    input wire change_in,
    input wire [7:0] bpm_in,
    input wire rst_in,
    input wire clk_camera_in,
    input wire valid_override_in, // button on the board
    input wire measure_in,
    output logic [7:0] bpm_out
);
    logic [30:0] cycle_counter;
    logic [6:0] hit_counter;
always_ff @(posedge clk_camera_in)begin
    if(rst_in)begin
        // reset all the variables
        bpm_out <= 8'd240; // default value of bpm is 60
        cycle_counter <= 0;
        hit_counter <= 0;
    end else begin
        if(valid_override_in)begin
            // if there is a valid override for the bpm, then the output of the
            // module will be overriden
            bpm_out <= bpm_in;
            cycle_counter <= 0;
        end else if (measure_in) begin
            cycle_counter <= 1;
            if(cycle_counter == 1_500_000_000)begin
                // done condition
                bpm_out <= hit_counter<<2; // must multiply by 4 to get bpm for 60 sec
                hit_counter <= 0;
                cycle_counter <= 0;
            end else if(change_in)begin
                hit_counter <= hit_counter + 1;
            end
        end
    end

end
endmodule
`default_nettype wire
