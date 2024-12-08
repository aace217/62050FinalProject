// `timescale 1ns / 1ps
// `default_nettype none

// module note_storing (
//     input wire [4:0][15:0] received_note,
//     input wire valid_note_in,
//     input wire [4:0] note_on_in,
//     input wire clk_camera_in,
//     input wire rst_in,
//     input wire [4:0][7:0] notes_in,
//     input wire [4:0][29:0] durations_in
// );

// // eight possible durations
// // note (sharp or no sharp) or rest
// // stem or no stem
// // dotted, not dotted

// // draw all the circles first
// // draw all five notes (+ sharps if needed) or rests (if at least one note, don't draw rests. only if all five notes are rests can you draw ONE rest)
// // if note, draw stem from lowest note to 20 pixels above top note
// // draw dot or not

// logic [4:0][5:0] note_rhythms;
// logic [1:0] measure;
// logic [4:0][37:0] cycles_in;
// logic [3:0] storing_state;
// localparam CYCLES_PER_BEAT = 60*200_000_000;

// enum logic [3:0] {  
//     // SIXTEENTH_UP, SIXTEENTH_DOWN, SIXTEENTH_REST, SIXTEENTH_SHARP_UP, SIXTEENTH_SHARP_DOWN, 
//         // EIGHTH_UP, EIGHTH_DOWN, EIGHTH_REST, EIGHTH_DOTTED_UP, EIGHTH_DOTTED_DOWN, EIGHTH_DOTTED_REST,
//         // EIGHTH_SHARP_UP, EIGHTH_SHARP_DOWN, EIGHTH_SHARP_DOTTED_UP, EIGHTH_SHARP_DOTTED_DOWN, 
//         // QUARTER_UP, QUARTER_DOWN, QUARTER_REST, QUARTER_DOTTED_UP, QUARTER_DOTTED_DOWN, QUARTER_DOTTED_REST,
//         // QUARTER_SHARP_UP, QUARTER_SHARP_DOWN, QUARTER_SHARP_DOTTED_UP, QUARTER_SHARP_DOTTED_DOWN,
//         // HALF_SHARP_UP, HALF_SHARP_DOWN, HALF_SHARP_DOTTED_UP, HALF_SHARP_DOTTED_DOWN, WHOLES_SHARP, 
//         // // HALF_UP, HALF_DOWN, HALF_REST, HALF_DOTTED_UP, HALF_DOTTED_DOWN, HALF_DOTTED_REST, WHOLE, WHOLE_REST,
//         SIXTEENTH, EIGHTH, DOTTED_EIGHTH, QUARTER, DOTTED_QUARTER, HALF, DOTTED_HALF, WHOLE, IDLE, STORING};

// assign storing_state = (durations_in == 0)?

// assign cycles_in[4] = durations_in[4]*bpm;
// assign cycles_in[3] = durations_in[3]*bpm;
// assign cycles_in[2] = durations_in[2]*bpm;
// assign cycles_in[1] = durations_in[1]*bpm;
// assign cycles_in[0] = durations_in[0]*bpm;

// logic [4:0][10:0] x_stem;
// logic [4:0][9:0] y_stem;
// logic [4:0][8:0] x_dot;
// logic [4:0][7:0] y_dot;
// logic [4:0][5:0] rhythm_width;
// logic x_counter, y_counter; // xcounter max depends on rhythm, y counter is 35


// // FOR NOW, let's set only one possible line to be starting at (0, 75)
// localparam STAFF_OFFSET = 66;

// always_comb begin
//     for (int i = 0; i < 5; i++) begin
//         case (notes_in[i][7:4])
//             0: begin // C; 7 notes per octave, 6 pixels per note
//                 y_dot[i] = (0 + 6*7*(8 - notes_in[i][3:0]) < STAFF_OFFSET)?
//                            0: ((0 + 6*7*(8 - notes_in[i][3:0]) - STAFF_OFFSET) > 180)?
//                            176: 0 + 6*7*(8 - notes_in[i][3:0]) - STAFF_OFFSET; 
//                 y_stem[i] = (note[i][3:0] < 5)? y_dot[i] - 18: y_dot[i] + 7;
//             end
//             1: begin // C sharp; 7 notes per octave, 6 pixels per note
//                 y_dot[i] = (0 + 6*7*(8 - notes_in[i][3:0]) < STAFF_OFFSET)?
//                            0: ((0 + 6*7*(8 - notes_in[i][3:0]) - STAFF_OFFSET) > 180)?
//                            176: 0 + 6*7*(8 - notes_in[i][3:0]) - STAFF_OFFSET; 
//                 y_stem[i] = (note[i][3:0] < 5)? y_dot[i] - 18: y_dot[i] + 7;
//             end            
//             2:  begin // D sharp; 7 notes per octave, 6 pixels per note
//                 y_dot[i] = (18 + 6*7*(8 - notes_in[i][3:0]) < STAFF_OFFSET)?
//                            18: ((18 + 6*7*(8 - notes_in[i][3:0]) - STAFF_OFFSET) > 180)?
//                            176: 18 + 6*7*(8 - notes_in[i][3:0]) - STAFF_OFFSET; 
//                 y_stem[i] = (note[i][3:0] < 5)? y_dot[i] - 18: y_dot[i] + 7;
//             end    3: begin // D sharp; 7 notes per octave, 6 pixels per note
//                 y_dot[i] = (18 + 6*7*(8 - notes_in[i][3:0]) < STAFF_OFFSET)?
//                            18: ((18 + 6*7*(8 - notes_in[i][3:0]) - STAFF_OFFSET) > 180)?
//                            176: 18 + 6*7*(8 - notes_in[i][3:0]) - STAFF_OFFSET; 
//                 y_stem[i] = (note[i][3:0] < 5)? y_dot[i] - 18: y_dot[i] + 7;
//             end            
//             4: begin // E; 7 notes per octave, 6 pixels per note
//                 y_dot[i] = (15 + 6*7*(8 - notes_in[i][3:0]) < STAFF_OFFSET)?
//                            15: ((15 + 6*7*(8 - notes_in[i][3:0]) - STAFF_OFFSET) > 180)?
//                            176: 15 + 6*7*(8 - notes_in[i][3:0]) - STAFF_OFFSET; 
//                 y_stem[i] = (note[i][3:0] < 5)? y_dot[i] - 18: y_dot[i] + 7;
//             end
//             5: begin // F; 7 notes per octave, 6 pixels per note
//                 y_dot[i] = (12 + 6*7*(8 - notes_in[i][3:0]) < STAFF_OFFSET)?
//                            12: ((12 + 6*7*(8 - notes_in[i][3:0]) - STAFF_OFFSET) > 180)?
//                            176: 12 + 6*7*(8 - notes_in[i][3:0]) - STAFF_OFFSET; 
//                 y_stem[i] = (note[i][3:0] < 5)? y_dot[i] - 18: y_dot[i] + 7;
//             end            
//             6: begin // F sharp; 7 notes per octave, 6 pixels per note
//                 y_dot[i] = (12 + 6*7*(8 - notes_in[i][3:0]) < STAFF_OFFSET)?
//                            12: ((12 + 6*7*(8 - notes_in[i][3:0]) - STAFF_OFFSET) > 180)?
//                            176: 12 + 6*7*(8 - notes_in[i][3:0]) - STAFF_OFFSET; 
//                 y_stem[i] = (note[i][3:0] < 5)? y_dot[i] - 18: y_dot[i] + 7;
//             end
//             7:  begin // G; 7 notes per octave, 6 pixels per note
//                 y_dot[i] = (9 + 6*7*(8 - notes_in[i][3:0]) < STAFF_OFFSET)?
//                            9: ((9 + 6*7*(8 - notes_in[i][3:0]) - STAFF_OFFSET) > 180)?
//                            176: 9 + 6*7*(8 - notes_in[i][3:0]) - STAFF_OFFSET; 
//                 y_stem[i] = (note[i][3:0] < 5)? y_dot[i] - 18: y_dot[i] + 7;
//             end            
//             8:  begin // G sharp; 7 notes per octave, 6 pixels per note
//                 y_dot[i] = (9 + 6*7*(8 - notes_in[i][3:0]) < STAFF_OFFSET)?
//                            9: ((9 + 6*7*(8 - notes_in[i][3:0]) - STAFF_OFFSET) > 180)?
//                            176: 9 + 6*7*(8 - notes_in[i][3:0]) - STAFF_OFFSET; 
//                 y_stem[i] = (note[i][3:0] < 5)? y_dot[i] - 18: y_dot[i] + 7;
//             end            
//             9:  begin // A; 7 notes per octave, 6 pixels per note
//                 y_dot[i] = (6 + 6*7*(8 - notes_in[i][3:0]) < STAFF_OFFSET)?
//                            6: ((6 + 6*7*(8 - notes_in[i][3:0]) - STAFF_OFFSET) > 180)?
//                            176: 6 + 6*7*(8 - notes_in[i][3:0]) - STAFF_OFFSET; 
//                 y_stem[i] = (note[i][3:0] < 5)? y_dot[i] - 18: y_dot[i] + 7;
//             end            
//             10: begin // A sharp; 7 notes per octave, 6 pixels per note
//                 y_dot[i] = (6 + 6*7*(8 - notes_in[i][3:0]) < STAFF_OFFSET)?
//                            6: ((6 + 6*7*(8 - notes_in[i][3:0]) - STAFF_OFFSET) > 180)?
//                            176: 6 + 6*7*(8 - notes_in[i][3:0]) - STAFF_OFFSET; 
//                 y_stem[i] = (note[i][3:0] < 5)? y_dot[i] - 18: y_dot[i] + 7;
//             end
//             11: begin // B; 7 notes per octave, 6 pixels per note
//                 y_dot[i] = (3 + 6*7*(8 - notes_in[i][3:0]) < STAFF_OFFSET)?
//                            3: ((3 + 6*7*(8 - notes_in[i][3:0]) - STAFF_OFFSET) > 180)?
//                            176: 3 + 6*7*(8 - notes_in[i][3:0]) - STAFF_OFFSET; 
//                 y_stem[i] = (note[i][3:0] < 5)? y_dot[i] - 18: y_dot[i] + 7;
//             end            
//             default: begin
//                 y_stem[i] = 0;
//                 y_dot[i] = 0;
//             end
//         endcase
//     end
// end


// always_comb begin
//     for (int i = 0; i < 5; i++) begin
//         if ((cycles_in[i] >= 0) && (cycles_in[i] < 3/8*CYCLES_PER_BEAT)) begin
//             note_rhythms[i] = SIXTEENTH; // 5 bit dot
//             x_stem[i] = x_counter;
//             x_dot[i] = x_counter;
//             rhythm_width = 5;
//         end else if ((cycles_in[i] >= 3/8*CYCLES_PER_BEAT) && (cycles_in[i] < 7/16*CYCLES_PER_BEAT)) begin
//             note_rhythms[i] = EIGHTH; // 6 bit dot
//             x_stem[i] = x_counter-10;
//             x_dot[i] = x_counter;
//             rhythm_width = 10;
//         end else if ((cycles_in[i] >= 7/16*CYCLES_PER_BEAT) && (cycles_in[i] < 11/16*CYCLES_PER_BEAT)) begin
//             note_rhythms[i] = DOTTED_EIGHTH; // 6 bit dot
//             x_stem[i] = x_counter-15;
//             x_dot[i] = x_counter - 10;
//             rhythm_width = 15;
//         end else if ((cycles_in[i] >= 11/16*CYCLES_PER_BEAT) && (cycles_in[i] < 5/4*CYCLES_PER_BEAT)) begin
//             note_rhythms[i] = QUARTER; // 7 bit dot
//             x_stem[i] = x_counter-20;
//             x_dot[i] = x_counter - 13;
//             rhythm_width = 20;
//         end else if ((cycles_in[i] >= 5/4*CYCLES_PER_BEAT) && (cycles_in[i] < 7/4*CYCLES_PER_BEAT)) begin
//             note_rhythms[i] = DOTTED_QUARTER;
//             x_stem[i] = x_counter-30;
//             x_dot[i] = x_counter - 18;
//             rhythm_width = 30;
//         end else if ((cycles_in[i] >= 7/4*CYCLES_PER_BEAT) && (cycles_in[i] < 5/2*CYCLES_PER_BEAT)) begin
//             note_rhythms[i] = HALF;
//             x_stem[i] = x_counter-40;
//             x_dot[i] = x_counter - 23;
//             rhythm_width = 40;
//         end else if ((cycles_in[i] >= 5/2*CYCLES_PER_BEAT) && (cycles_in[i] < 7/2*CYCLES_PER_BEAT)) begin
//             note_rhythms[i] = DOTTED_HALF;
//             x_stem[i] = x_counter-60;
//             x_dot[i] = x_counter - 33;
//             rhythm_width = 60;
//         end else if ((cycles_in[i] >= 7/2*CYCLES_PER_BEAT) && (cycles_in[i] < 4*CYCLES_PER_BEAT)) begin
//             note_rhythms[i] = WHOLE; // 9 bit dot
//             rhythm_width = 80;
//             x_stem[i] = x_counter-80;
//             x_dot[i] = x_counter - 45;
//         end
//         // // SIXTEENTH NOTES
//         // if (   (cycles_in[i] < 1/4*CYCLES_PER_BEAT + 1/8*CYCLES_PER_BEAT ) 
//         //     || (cycles_in[i] > 1/4*CYCLES_PER_BEAT - 1/8*CYCLES_PER_BEAT)) begin // 16th
//         //     if (notes_in[i][7:4] != 0 || notes_in[i][3:0] != 0) begin // note
//         //         if ((notes_in[i][7:4] == 1) || (notes_in[i][7:4] == 3) || (notes_in[i][7:4] == 6) || (notes_in[i][7:4] == 8) || (notes_in[i][7:4] == 10)) begin // sharp
//         //             note_rhythms[i] = (notes_in[i][3:0] < 5)? SIXTEENTH_SHARP_DOWN: SIXTEENTH_SHARP_UP;
//         //         end else begin // not sharp
//         //             note_rhythms[i] = (notes_in[i][3:0] < 5)? SIXTEENTH_DOWN: SIXTEENTH_UP;
//         //         end
//         //     end else begin // rest 
//         //         note_rhythms[i] = SIXTEENTH_REST;
//         //     end
//         // // EIGHTH NOTES
//         // end else if (  (cycles_in[i] < 1/2*CYCLES_PER_BEAT + 1/4*CYCLES_PER_BEAT ) // 8th 
//         //             || (cycles_in[i] > 1/2*CYCLES_PER_BEAT - 1/4*CYCLES_PER_BEAT)) begin 
//         //     if (notes_in[i][7:4] != 0 || notes_in[i][3:0] != 0) begin // note
//         //         if ((notes_in[i][7:4] == 1) || (notes_in[i][7:4] == 3) || (notes_in[i][7:4] == 6) || (notes_in[i][7:4] == 8) || (notes_in[i][7:4] == 10)) begin // sharp
//         //             note_rhythms[i] = (notes_in[i][3:0] < 5)? EIGHTH_SHARP_DOWN: EIGHTH_SHARP_UP;
//         //         end else begin // not sharp
//         //             note_rhythms[i] = (notes_in[i][3:0] < 5)? EIGHTH_DOWN: EIGHTH_UP;
//         //         end
//         //     end else begin // rest 
//         //         note_rhythms[i] = EIGHTH_REST;
//         //     end
//         // // DOTTED EIGHTH NOTES
//         // end else if (  (cycles_in[i] < 3/8*CYCLES_PER_BEAT + 3/16*CYCLES_PER_BEAT ) // dotted 8th
//         //             || (cycles_in[i] > 3/8*CYCLES_PER_BEAT - 3/16*CYCLES_PER_BEAT)) begin 
//         //     if (notes_in[i][7:4] != 0 || notes_in[i][3:0] != 0) begin // note
//         //         if ((notes_in[i][7:4] == 1) || (notes_in[i][7:4] == 3) || (notes_in[i][7:4] == 6) || (notes_in[i][7:4] == 8) || (notes_in[i][7:4] == 10)) begin // sharp
//         //             note_rhythms[i] = (notes_in[i][3:0] < 5)? EIGHTH_SHARP_DOTTED_DOWN: EIGHTH_SHARP_DOTTED_UP;
//         //         end else begin // not sharp
//         //             note_rhythms[i] = (notes_in[i][3:0] < 5)? EIGHTH_DOTTED_DOWN: EIGHTH_DOTTED_UP;
//         //         end
//         //     end else begin // rest 
//         //         note_rhythms[i] = EIGHTH_DOTTED_REST;
//         //     end
//         // // QUARTER NOTES
//         // end else if (  (cycles_in[i] < 1*CYCLES_PER_BEAT + 1/2*CYCLES_PER_BEAT ) // quarter
//         //             || (cycles_in[i] > 1*CYCLES_PER_BEAT - 1/2*CYCLES_PER_BEAT)) begin 
//         //     if (notes_in[i][7:4] != 0 || notes_in[i][3:0] != 0) begin // note
//         //         if ((notes_in[i][7:4] == 1) || (notes_in[i][7:4] == 3) || (notes_in[i][7:4] == 6) || (notes_in[i][7:4] == 8) || (notes_in[i][7:4] == 10)) begin // sharp
//         //             note_rhythms[i] = (notes_in[i][3:0] < 5)? QUARTER_SHARP_DOWN: QUARTER_SHARP_UP;
//         //         end else begin // not sharp
//         //             note_rhythms[i] = (notes_in[i][3:0] < 5)? QUARTER_DOWN: QUARTER_UP;
//         //         end
//         //     end else begin // rest 
//         //         note_rhythms[i] = QUARTER_REST;
//         //     end
//         // // DOTTED QUARTER NOTES
//         // end else if (  (cycles_in[i] < 3/2*CYCLES_PER_BEAT + 3/4*CYCLES_PER_BEAT ) // dotted quarter
//         //             || (cycles_in[i] > 3/2*CYCLES_PER_BEAT - 3/4*CYCLES_PER_BEAT)) begin 
//         //     if (notes_in[i][7:4] != 0 || notes_in[i][3:0] != 0) begin // note
//         //         if ((notes_in[i][7:4] == 1) || (notes_in[i][7:4] == 3) || (notes_in[i][7:4] == 6) || (notes_in[i][7:4] == 8) || (notes_in[i][7:4] == 10)) begin // sharp
//         //             note_rhythms[i] = (notes_in[i][3:0] < 5)? QUARTER_SHARP_DOTTED_DOWN: QUARTER_SHARP_DOTTED_UP;
//         //         end else begin // not sharp
//         //             note_rhythms[i] = (notes_in[i][3:0] < 5)? QUARTER_DOTTED_DOWN: QUARTER_DOTTED_UP;
//         //         end
//         //     end else begin // rest 
//         //         note_rhythms[i] = QUARTER_DOTTED_REST;
//         //     end
//         // // HALF NOTES
//         // end else if (  (cycles_in[i] < 2*CYCLES_PER_BEAT + 1*CYCLES_PER_BEAT ) // half
//         //             || (cycles_in[i] > 2*CYCLES_PER_BEAT - 1*CYCLES_PER_BEAT)) begin 
//         //     if (notes_in[i][7:4] != 0 || notes_in[i][3:0] != 0) begin // note
//         //         if ((notes_in[i][7:4] == 1) || (notes_in[i][7:4] == 3) || (notes_in[i][7:4] == 6) || (notes_in[i][7:4] == 8) || (notes_in[i][7:4] == 10)) begin // sharp
//         //             note_rhythms[i] = (notes_in[i][3:0] < 5)? HALF_SHARP_DOWN: HALF_SHARP_UP;
//         //         end else begin // not sharp
//         //             note_rhythms[i] = (notes_in[i][3:0] < 5)? HALF_DOWN: HALF_UP;
//         //         end
//         //     end else begin // rest 
//         //         note_rhythms[i] = HALF_REST;
//         //     end
//         // end else if (  (cycles_in[i] < 3*CYCLES_PER_BEAT + 3/2*CYCLES_PER_BEAT ) // dotted half
//         //             || (cycles_in[i] > 3*CYCLES_PER_BEAT - 3/2*CYCLES_PER_BEAT)) begin 
//         //     if (notes_in[i][7:4] != 0 || notes_in[i][3:0] != 0) begin // note
//         //         if ((notes_in[i][7:4] == 1) || (notes_in[i][7:4] == 3) || (notes_in[i][7:4] == 6) || (notes_in[i][7:4] == 8) || (notes_in[i][7:4] == 10)) begin // sharp
//         //             note_rhythms[i] = (notes_in[i][3:0] < 5)? HALF_SHARP_DOTTED_DOWN: HALF_SHARP_DOTTED_UP;
//         //         end else begin // not sharp
//         //             note_rhythms[i] = (notes_in[i][3:0] < 5)? HALF_DOTTED_DOWN: HALF_DOTTED_UP;
//         //         end
//         //     end else begin // rest 
//         //         note_rhythms[i] = HALF_DOTTED_REST;
//         //     end
//         // end else (     (cycles_in[i] < 4*CYCLES_PER_BEAT + 2*CYCLES_PER_BEAT ) // whole
//         //             || (cycles_in[i] > 4*CYCLES_PER_BEAT - 2*CYCLES_PER_BEAT)) begin 
//         //     if (notes_in[i][7:4] != 0 || notes_in[i][3:0] != 0) begin // note
//         //         if ((notes_in[i][7:4] == 1) || (notes_in[i][7:4] == 3) || (notes_in[i][7:4] == 6) || (notes_in[i][7:4] == 8) || (notes_in[i][7:4] == 10)) begin // sharp
//         //             note_rhythms[i] = (notes_in[i][3:0] < 5)? WHOLE_SHARP_DOWN: WHOLE_SHARP_UP;
//         //         end else begin // not sharp
//         //             note_rhythms[i] = (notes_in[i][3:0] < 5)? WHOLE_DOWN: WHOLE_UP;
//         //         end
//         //     end else begin // rest 
//         //         note_rhythms[i] = WHOLE_REST;
//         //     end
//         // end
//     end
// end


// always_ff @(posedge clk_in) begin
//     // for (int i = 0; i < 5; i++) begin
//         // dot block depends on 16th/8th/quarter vs half/whole
//         // on right, dot depends on dotted or not
//         // on left, sharp depends on sharp or not
//         // stem depends on: 1) octave, and 2) 
//     // end
//     if (rst_in) begin
//         x_stem <= 0;
//         y_stem <= 0;
//         x_counter <= 0;
//         y_counter <= 0;
//         measure <= 0;
//     end else begin
//         if (notes_in == 0) begin
//             // just get the correct restbased on note_rhythms
//         end else if (y_counter >= y_dot[4] && y_counter < y_dot[4] + 7) begin
//             if (x_counter >= x_dot[4] && x_counter < x_dot[4] + 7) begin
//                 // get the bean based on note_rhythms
//             end else if (x_counter >= x_dot[4] - 5 && x_counter < x_dot[4]) begin
//                 // get the sharp
//             end else if (x_counter >= x_dot[4] + 7 && x_counter < x_dot[4] + 11) begin
//                 // get the dot
//             end else begin
//                 // get white
//             end
//         end else if (x_counter >= x_dot[3] && x_counter < x_dot[3] + 7 && y_counter >= y_dot[3] && y_counter < y_dot[3] + 7) begin
//         end else if (x_counter >= x_dot[2] && x_counter < x_dot[2] + 7 && y_counter >= y_dot[2] && y_counter < y_dot[2] + 7) begin
//         end else if (x_counter >= x_dot[1] && x_counter < x_dot[1] + 7 && y_counter >= y_dot[1] && y_counter < y_dot[1] + 7) begin
//         end else if (x_counter >= x_dot[0] && x_counter < x_dot[0] + 7 && y_counter >= y_dot[0] && y_counter < y_dot[0] + 7) begin
//         end else if (more top heavy) begin
//             // use note_rhythms to choose downwards stem
//         end else if (more botom heavy) begin
//             // use note_rhythms to choose upwards stem
//         end
//         x_counter <= (max)?0 : x_counter + 1;
//         y_counter <= (max)? 0 : y_counter + 1;
//         // measure // increments 1 every 160,000,000 cycles
//     end

// end





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



// endmodule

// `default_nettype wire
