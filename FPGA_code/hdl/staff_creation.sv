`timescale 1ns / 1ps
`default_nettype none

module staff_creation (
    input wire [10:0] hcount,
    input wire [9:0] vcount, 
    input wire [7:0] bpm,
    input wire [79:0] received_note,
    input wire clk_camera_in,
    input wire rst_in,
    output logic [1:0] staff_out,
    output logic staff_valid
);

assign staff_out = 0;

logic buf1, buf2, buf3;

always_ff @(posedge clk_camera_in) begin
    buf1 <= 1;
    buf2 <= 2;
    buf3 <= buf2;
    staff_valid <= buf3;
end

endmodule

`default_nettype wire
