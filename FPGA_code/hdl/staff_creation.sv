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

// this is actually cycles_per_beat * bpm
// we want to compare duration (input number of cycles) to number of cycles per beat = 60 sec * 200MHz/n bpm
// to avoid division, multiply input number of cycles instead and compare that to 60 sec * 200MHz
// localparam CYCLES_PER_BEAT = 60*200_000_000;
// logic [4:0][37:0] cycles_in;
// logic [4:0][5:0] note_rhythms;
// enum {  SIXTEENTH_UP, SIXTEENTH_DOWN, SIXTEENTH_REST, 
//         EIGHTH_UP, EIGHTH_DOWN, EIGHTH_REST, EIGHTH_DOTTED_UP, EIGHTH_DOTTED_DOWN, EIGHT_DOTTED_REST,
//         QUARTER_UP, QUARTER_DOWN, QUARTER_REST, QUARTER_DOTTED_UP, QUARTER_DOTTED_DOWN, QUARTER_DOTTED_REST,
//         HALF_UP, HALF_DOWN, HALF_REST, HALF_DOTTED_UP, HALF_DOTTED_DOWN, HALF_DOTTED_REST, WHOLE, WHOLE_REST};

// assign cycles_in[4] = durations_in[4]*bpm;
// assign cycles_in[3] = durations_in[3]*bpm;
// assign cycles_in[2] = durations_in[2]*bpm;
// assign cycles_in[1] = durations_in[1]*bpm;
// assign cycles_in[0] = durations_in[0]*bpm;

// if (in)


// xilinx_single_port_ram_read_first #(
//     .RAM_WIDTH(8),                       // Specify RAM data width
//     .RAM_DEPTH(19500),                     // Specify RAM depth (number of entries)
//     .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
//     .INIT_FILE(`FPATH(image.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
//   ) image_BROM (
//     .addra(image_addr),     // Address bus, width determined from RAM_DEPTH
//     .dina(0),       // RAM input data, width determined from RAM_WIDTH
//     .clka(pixel_clk_in),       // Clock
//     .wea(0),         // Write enable
//     .ena(1),         // RAM Enable, for additional power savings, disable port when not in use
//     .rsta(rst_in),       // Output reset (does not affect memory contents)
//     .regcea(1),   // Output register enable
//     .douta(pxl_color_addr)      // RAM output data, width determined from RAM_WIDTH
//   );



// _____________________________________________
// find the correct y location/pitch for the note

// get the correct x location on the staff by replotting all the previously stored notes

// store the new note as well
// localparam STAFF_HCOUNT_MAX = 36*num_lines;


assign staff_out = 0;

logic buf1, buf2, buf3;
always_ff @(posedge clk_camera_in) begin

    // for (int i = 0; i < STAFF_HCOUNT_MAX; i = i + num_lines) begin
  buf1 <= 1;
  buf2 <= buf1;
  buf3 <= buf2;
  staff_valid <= buf3;
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

    end
// end

endmodule

`default_nettype wire
