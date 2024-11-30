`timescale 1ns / 1ps
`default_nettype none

module staff_creation (
    input wire [10:0] hcount,
    input wire [9:0] vcount, 
    input wire [7:0] bpm,
    input wire [7:0] notes_in [4:0],
    input wire [29:0] durations_in [4:0],
    input wire clk_camera_in,
    input wire rst_in,
    input wire [2:0] num_lines,
    output logic [1:0] staff_out,
    output logic staff_valid
);

// _____________________________________________
// map this duration to the correct note image

// _____________________________________________
// find the correct y location/pitch for the note

// get the correct x location on the staff by replotting all the previously stored notes

// store the new note as well
// localparam STAFF_HCOUNT_MAX = 36*num_lines;


// assign staff_out = 0;

// logic buf1, buf2, buf3;
// always_ff @(posedge clk_camera_in) begin

//     for (int i = 0; i < STAFF_HCOUNT_MAX; i = i + num_lines) begin
//         buf1 <= 1;
//         buf2 <= buf1;
//         buf3 <= buf2;
//         staff_valid <= buf3;
//         if (vcount == 36*(num_lines-1) ||
//             vcount == 36*(num_lines-xcfcxffx1) + 6 ||
//             vcount == 36*(num_lines-1) + 12 ||
//             vcount == 36*(num_lines-1) + 18 ||
//             vcount == 36*(num_lines-1) + 24
//         ) begin
//             staff_out <= 2'b11;
//         end else if ((hcount >= 36*(num_lines-1) && hcount <= (num_lines-1) + 24) &&
//                      (vcount == 80 || vcount == 160 || vcount == 240)
//                     ) begin
//             staff_out <= 2'b11;
//         end else begin
//             staff_out <= 0;
//         end

//     end
// end

endmodule

`default_nettype wire
