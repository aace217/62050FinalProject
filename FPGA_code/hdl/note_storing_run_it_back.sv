`timescale 1ns / 1ps
`default_nettype none

`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"../../data/X`"
`endif  /* ! SYNTHESIS */

module note_storing_run_it_back (
    input wire clk_in,
    input wire rst_in,
    input wire [7:0] bpm,
    input wire [2:0] num_lines,
    input wire  [7:0] notes_in [4:0],
    input wire  [29:0] durations_in[4:0],
    output logic [15:0] addr_out,
    output logic [15:0] mem_out,
    output logic [11:0] note_memory [4:0][63:0],
    output logic [31:0] sixteenth_metronome,
    output logic [5:0] current_staff_cell,
    output logic storing_state_out,
    output logic [3:0] note_rhythms [4:0]
);

logic [4:0][7:0] notes_in_test;
logic [4:0][29:0] durations_in_test;
logic [4:0][3:0] note_rhythms_test;
logic [4:0][3:0] note_rhythm_buffer_test;
logic [2:0][11:0] note_memory_test1;
always_comb begin
    for (int i = 0; i < 5; i++) begin
        notes_in_test[i] = notes_in[i];
        durations_in_test[i] = durations_in[i];
        note_rhythms_test[i] = note_rhythms[i];
        note_rhythm_buffer_test[i]= note_rhythm_buffer[i];
    end
        // note_memory_test1 = note_memory[i][];
    for (int j = 0; j < 3; j++) begin
        note_memory_test1[j] = note_memory[0][j];
    end
end


//________________________________________________________________________
// SETTING UP METRONOME, BPM ON 16th NOTE 

logic [4:0][5:0] start_staff_cell;

always_ff @(posedge clk_in) begin
    if (rst_in) begin
        sixteenth_metronome <= 0;
        current_staff_cell <= 0;
    end else begin
        sixteenth_metronome <= (sixteenth_metronome + (bpm >> 2) >= 1_500_000_000)? 0 : sixteenth_metronome + (bpm >> 2);
    end
end

//________________________________________________________________________
// GETTING X (NOTE RHYTHM), Y (Y DOT) OF EACH INPUTTED NOTE 

localparam CYCLES_PER_BEAT = 60*100_000_000;
logic [4:0][35:0] cycles_in;
// max cycles in is max duration, 1_200_000_000 cycles times its bpm 40 which is 48_000_000_000
// basically 60*200_000_000 cycles per beat * 4 quarter notes

assign cycles_in[4] = durations_in[4]*(bpm >> 2);
assign cycles_in[3] = durations_in[3]*(bpm >> 2);
assign cycles_in[2] = durations_in[2]*(bpm >> 2);
assign cycles_in[1] = durations_in[1]*(bpm >> 2);
assign cycles_in[0] = durations_in[0]*(bpm >> 2);


localparam [3:0] SIXTEENTH = 1;
localparam [3:0] EIGHTH = 2;
localparam [3:0] DOTTED_EIGHTH = 3;
localparam [3:0] QUARTER = 4;
localparam [3:0] DOTTED_QUARTER = 6;
localparam [3:0] HALF = 8;
localparam [3:0] DOTTED_HALF = 12;
localparam [3:0] WHOLE = 0;
localparam [3:0] NULL = 13;
// typedef enum logic [3:0] {  EIGHTH = 2, DOTTED_EIGHTH = 3, QUARTER = 4, DOTTED_QUARTER = 6, HALF = 8, DOTTED_HALF = 12, WHOLE = 0, NULL = 13} note_rhythm;
logic [3:0] note_rhythm_buffer[4:0] ;

logic [4:0][7:0] y_dot;


logic [6:0] note_width [4:0];
logic [2:0] sharp_shift [4:0];
logic [7:0] rhythm_shift [4:0];

assign sharp_shift[0] = (  (note_memory[0][start_staff_cell[0]][7:4] == 1) || 
                        (note_memory[0][start_staff_cell[0]][7:4] == 3) || 
                        (note_memory[0][start_staff_cell[0]][7:4] == 6) || 
                        (note_memory[0][start_staff_cell[0]][7:4] == 8) || 
                        (note_memory[0][start_staff_cell[0]][7:4] == 10)) ? 7 : 0;

always_comb begin
    for (int i = 0; i < 5; i++) begin
        //(3/8)*CYCLES_PER_BEAT) = 4_500_000_000
        if ((cycles_in[i] >= 0) && (cycles_in[i] < 64'd2_250_000_000)) begin
            note_rhythms[i] = SIXTEENTH; // 5 bit dot
            note_width[0] = 5;
            rhythm_shift[0] = (note_memory[0][start_staff_cell[0]][3:0] < 5)? 0 : 5;
            // check[i] = 0;
        // (7/16)*CYCLES_PER_BEAT = 5_250_000_000
        end else if ((cycles_in[i] >= 64'd2_250_000_000) && (cycles_in[i] < 64'd2_625_000_000)) begin
            note_rhythms[i] = EIGHTH; // 6 bit dot
            note_width[0] = 10;
            rhythm_shift[0] = 10;
            // check[i] = 1;
        //(11/16)*CYCLES_PER_BEAT = 8_250_000_000
        end else if ((cycles_in[i] >= 64'd2_625_000_000) && (cycles_in[i] < 64'd4_125_000_000)) begin
            note_rhythms[i] = DOTTED_EIGHTH; // 6 bit dot
            note_width[0] = 15;
            rhythm_shift[0] = 20;
            // check[i] = 2;
        //(5/4)*CYCLES_PER_BEAT = 15_000_000_000
        end else if ((cycles_in[i] >= 64'd4_125_000_000) && (cycles_in[i] < 64'd7_500_000_000)) begin
            note_rhythms[i] = QUARTER; // 7 bit dot
            note_width[0] = 20;
            rhythm_shift[0] = 35;
            // check[i] = ((11/16)*CYCLES_PER_BEAT);
        // (7/4)*CYCLES_PER_BEAT = 21_000_000_000
        end else if ((cycles_in[i] >= 64'd7_500_000_000) && (cycles_in[i] < 64'd10_500_000_000)) begin
            note_rhythms[i] = DOTTED_QUARTER;
            note_width[0] = 30;
            rhythm_shift[0] = 55;
             // check[i] = 4;
        // (5/2)*CYCLES_PER_BEAT = 30_000_000_000
        end else if ((cycles_in[i] >= 64'd10_500_000_000) && (cycles_in[i] < 64'd15_000_000_000)) begin
            note_rhythms[i] = HALF;
            note_width[0] = 40;
            rhythm_shift[0] = 85;
            // check[i] = 5;
        //(7/2)*CYCLES_PER_BEAT = 42_000_000_000
        end else if ((cycles_in[i] >= 64'd15_000_000_000) && (cycles_in[i] < 64'd21_000_000_000)) begin
            note_rhythms[i] = DOTTED_HALF;
            note_width[0] = 60;
            rhythm_shift[0] = 125;
            // check[i] = 6;
        //4*CYCLES_PER_BEAT = 48_000_000_000
        end else if ((cycles_in[i] >= 64'd21_000_000_000) && (cycles_in[i] < 64'd24_000_000_000)) begin
            note_rhythms[i] = WHOLE; // 9 bit dot
            note_width[0] = 80;
            rhythm_shift[0] = 185;
            // check[i] = 7;
        end
    end
end

always_comb begin
    for (int i = 0; i < 5; i++) begin
        case (notes_in[i][7:4])
            0,1: y_dot[i] = 0 + 6*7*(8 - notes_in[i][3:0]);  // C; 7 notes per octave, 6 pixels per note
            2,3: y_dot[i] = 18 + 6*7*(8 - notes_in[i][3:0]);  // D sharp; 7 notes per octave, 6 pixels per note
            4: y_dot[i] = 15 + 6*7*(8 - notes_in[i][3:0]);  // E; 7 notes per octave, 6 pixels per note
            5,6: y_dot[i] = 12 + 6*7*(8 - notes_in[i][3:0]);  // F; 7 notes per octave, 6 pixels per note  
            7,8: y_dot[i] = 9 + 6*7*(8 - notes_in[i][3:0]);  // G; 7 notes per octave, 6 pixels per note        
            9,10: y_dot[i] = 6 + 6*7*(8 - notes_in[i][3:0]);  // A; 7 notes per octave, 6 pixels per note          
            11: y_dot[i] = 3 + 6*7*(8 - notes_in[i][3:0]);  // B; 7 notes per octave, 6 pixels per note        
            default: y_dot[i] = 150;
        endcase
    end
end

//________________________________________________________________________
// STORING PIXELS OF CORRESPONDING NOTES
// this all needs to happen within 3_000_000_000 cycles

localparam STAFF_SHIFT = 130;
localparam STAFF_HEIGHT = 35;
logic [2:0] note_ind;
logic [2:0] staff_ind;
enum logic [3:0] {INIT = 0, IDLE = 1, NOTE = 2, TRACK = 3} storing_state;

assign storing_state_out = storing_state;

logic [4:0][6:0] x_start;
logic [4:0] [7:0] y_start; // c0 -> c8 leads to 336 possible y locations
logic [8:0] x_counter; // can go up to 80 for notes
logic [7:0] y_counter; // can go up to 7 for notes

logic [3:0] check3;
logic [3:0] check1;
logic [3:0] check2;

logic [15:0] addr_buf1, addr_buf2;

logic [5:0] x_test, y_test;

// always_ff @(posedge clk_in) begin
//     image_addr <= (y_test+7) * 265 + (x_test + 35);
//     x_test <= (x_test == 19)? 0: x_test + 1;
//     y_test <= (x_test == 19)? (y_test == 6)? 0: y_test + 1 : y_test;
//     addr_buf1 <= (y_test) * 320 + (x_test);
//     addr_out <= addr_buf1;
//     // addr_out <= addr_buf2;
//     // for (int i = 0; i < 64; i++) begin
//     //     for (int j = 0; j < 5; j++) begin
//     //         for (int x = 0; x < 5; x ++) begin
//     //             for (int y = 0; y < 7; y ++) begin
//     //                 image_addr <= (0 + y) * 265 + (0 + x);
//     //                 addr_buf1 <= (j*7 + y) * 320 + (i*5 + x);
//     //                 addr_buf2 <= addr_buf1;
//     //                 addr_out <= addr_buf2;
//     //             end
//     //         end
//     //     end
//     // end
// end


always_ff @(posedge clk_in) begin
    if (rst_in) begin
        note_ind <= 0;
        storing_state <= INIT;
        start_staff_cell <= 0;
        for (int i = 0; i < 5; i++) begin
            for (int j = 0 ; j < 64; j++) begin
                note_memory[i][j] <= 0;
            end
        end
        x_start <= 0;
        y_start <= 0;
        x_counter <= 0;
        y_counter <= 0;
        image_addr <= 0;
        addr_out <= 0;        
    end else begin
        case (storing_state) // all happens within the same current_staff_cell, hopefully
            INIT: begin
                image_addr <= 0;
                x_counter <= (x_counter == 319)? 0: x_counter + 1;
                y_counter <= (x_counter == 319)? (y_counter == 179)? 0: y_counter + 1 : y_counter;
                addr_buf1 <= (y_counter) * 320 + (x_counter);
                addr_buf2 <= addr_buf1;
                addr_out <= addr_buf2;   
                storing_state <= (x_counter == 319 && y_counter == 179)? IDLE : INIT;
            end
            IDLE: begin
                current_staff_cell <= (sixteenth_metronome + (bpm >> 2) >= 1_500_000_000)? (current_staff_cell + 1 == 64)? 0 : current_staff_cell + 1 : current_staff_cell;
                if (sixteenth_metronome <= (bpm >> 2) && notes_in[0][7:0] != 8'hFF) begin
                    storing_state <= NOTE;
                    // If current note rhythm is not the same as the one stored at the start
                    if (note_rhythms[0] != note_memory[0][start_staff_cell[0]][11:8]) begin
                        
                        // If new note is SIXTEENTH, its the beginning of new note
                        // This occurs if note changes, or if it turns on/off, or if a new measure starts
                        start_staff_cell[0] <= (note_rhythms[0] == SIXTEENTH)? current_staff_cell : start_staff_cell[0];
                        x_start[0] <= (note_rhythms[0] == SIXTEENTH)? current_staff_cell * 5 : start_staff_cell * 5;
                        y_start[0] <= y_dot[0] - STAFF_SHIFT;

                        if (note_rhythms[0] == SIXTEENTH) begin 
                            note_memory[0][current_staff_cell][11:8] <= note_rhythms[0];
                            note_memory[0][current_staff_cell][7:0] <= notes_in[0];
                        // If just extending duration of any note
                        end else begin 
                            note_memory[0][start_staff_cell[0]][11:8] <= note_rhythms[0];
                            note_memory[0][start_staff_cell[0]][7:0] <= notes_in[0]; // store start to be able to break nulls
                            note_memory[0][current_staff_cell][11:8] <= NULL;
                        end
                    end
                end else begin
                    // storing_state <= TRACK;
                end
            end
            NOTE: begin
                // x_counter <= (x_counter == 4)? 0: x_counter + 1;
                // y_counter <= (x_counter == 4)? (y_counter == 6)? 0: y_counter + 1 : y_counter;
                // image_addr <= (y_counter + 0) * 265 + (0 + rhythm_shift[0]); // white pixel at address 19874 - white out if no note
                // addr_buf1 <= (0 + y_counter) * 320 + (0 + x_counter);
                // addr_buf2 <= addr_buf1;
                // addr_out <= addr_buf2;
                // storing_state <= (x_counter == (4) && y_counter == 6)? IDLE : STORING;
                x_counter <= (x_counter == note_width[0] - 1)? 0: x_counter + 1;
                y_counter <= (x_counter == note_width[0] - 1)? (y_counter == 6)? 0: y_counter + 1 : y_counter;
                // make a second x y counter for the entire hdmi screen separately; above is counter for image 
                image_addr <= (y_counter + sharp_shift[0]) * 265 + (x_counter + rhythm_shift[0]); // white pixel at address 19874 - white out if no note
                addr_buf1 <= (y_start[0] + y_counter) * 320 + (x_start[0] + x_counter);
                addr_buf2 <= addr_buf1;
                addr_out <= addr_buf2;
                storing_state <= (x_counter == (note_width[0] - 1) && y_counter == 6)? IDLE : NOTE;
            end
            TRACK: begin
                x_counter <= (x_counter == 319)? 0: x_counter + 1;
                image_addr <= (x_counter == current_staff_cell*5)? 2:0; // white pixel at address 19874 - white out if no note
                addr_buf1 <= (30) * 265 + (x_counter);
                addr_buf2 <= addr_buf1;
                addr_out <= addr_buf2;
                storing_state <= (x_counter == 319)? IDLE : TRACK;
            end
        endcase
    end
end



// // assign check1 = check[0];

// always_ff @(posedge clk_in) begin
//     if (rst_in) begin
//         note_ind <= 0;
//         storing_state <= IDLE;
//         start_staff_cell <= 0;
//         // note_memory <= 0;
//         for (int i = 0; i < 5; i++) begin
//             for (int j = 0 ; j < 64; j++) begin
//                 note_memory[i][j] <= 0;
//             end
//         end
//         x_start <= 0;
//         y_start <= 0;
//         x_counter <= 0;
//         y_counter <= 0;
//         image_addr <= 0;
//         addr_out <= 0;
//     end else begin
//         case(storing_state)
//             IDLE: begin
//                 for (int i = 0; i < 5; i ++) begin
//                     note_rhythm_buffer[i] <= note_rhythms[i];
//                 end
//                 if (sixteenth_metronome == bpm) begin
//                     storing_state <= STORING;
//                     x_counter <= 0;
//                     y_counter <= 0;
//                     for (int i = 0; i < 5; i ++) begin
//                         if (note_rhythms[i] != note_memory[i][start_staff_cell[i]][11:8]) begin
//                             if (note_rhythms[i] == SIXTEENTH) begin // beginning of new note
//                                 start_staff_cell[i] <= current_staff_cell;
//                                 note_memory[i][current_staff_cell][11:8] <= note_rhythms[i];
//                                 note_memory[i][start_staff_cell[i]][7:0] <= notes_in[i];
//                                 x_start[i] <= current_staff_cell * 5;
//                                 y_start[i] <= y_dot[i];
//                             end else begin // extending duration of any note
//                                 start_staff_cell[i] <= start_staff_cell[i];
//                                 note_memory[i][start_staff_cell[i]][11:8] <= note_rhythms[i];
//                                 note_memory[i][current_staff_cell][11:8] <= NULL;
//                                 note_memory[i][start_staff_cell[i]][7:0] <= notes_in[i];
//                                 x_start[i] <= start_staff_cell * 5;
//                                 y_start[i] <= y_dot[i];
//                             end
//                         end
//                     end
//                 end
//             end
//             STORING: begin // assuming this cycles to completion in less cycles than cycles it takes to change the input midi notes
//                 // iterate through just the cell and draw everything there
//                 // which means getting the y for each of the notes in that cell
//                 // draw stuff starting at start_staff_cell
//                 if (note_memory[0][current_staff_cell[note_ind]][7:4] == 0 && note_memory[0][current_staff_cell[note_ind]][3:0] == 0 &&
//                     note_memory[1][current_staff_cell[note_ind]][7:4] == 0 && note_memory[1][current_staff_cell[note_ind]][3:0] == 0 &&
//                     note_memory[2][current_staff_cell[note_ind]][7:4] == 0 && note_memory[2][current_staff_cell[note_ind]][3:0] == 0 &&
//                     note_memory[3][current_staff_cell[note_ind]][7:4] == 0 && note_memory[3][current_staff_cell[note_ind]][3:0] == 0 &&
//                     note_memory[4][current_staff_cell[note_ind]][7:4] == 0 && note_memory[4][current_staff_cell[note_ind]][3:0] == 0) 
//                 begin
//                     check2 <= 0;
//                     check1 <= 1;
//                     check3 <= 0;
//                     // get duration of shortest rest, store that
//                     // transition back to idle
//                     storing_state <= IDLE;
//                 end else if (note_memory[note_ind][start_staff_cell[note_ind]][7:4] != 0 || note_memory[note_ind][start_staff_cell[note_ind]][3:0] != 0) begin // only draw valid notes
//                     check2 <= 2;
//                     check1 <= 0;
//                     check3 <= 0;
//                     // output
//                     addr_out <= (y_start[note_ind] + y_counter) * 320 + (x_start[note_ind] + x_counter);
                   
//                     case (note_memory[note_ind][start_staff_cell[note_ind]][11:8]) // case on type of note rhythm
//                         SIXTEENTH: begin
//                             // check if note is sharp
//                             if ((note_memory[note_ind][start_staff_cell[note_ind]][7:4] == 1) || 
//                             (note_memory[note_ind][start_staff_cell[note_ind]][7:4] == 3) || 
//                             (note_memory[note_ind][start_staff_cell[note_ind]][7:4] == 6) || 
//                             (note_memory[note_ind][start_staff_cell[note_ind]][7:4] == 8) || 
//                             (note_memory[note_ind][start_staff_cell[note_ind]][7:4] == 10)) 
//                             begin
//                                 image_addr <= (note_memory[note_ind][start_staff_cell[note_ind]][3:0] < 5)? // up or down circle
//                                               (7 + y_counter) * 265 + (0 + x_counter) : (7 + y_counter) * 265 + (5 + x_counter);
//                             end else if (note_memory[note_ind][start_staff_cell[note_ind]][7:4] == 0 && note_memory[note_ind][start_staff_cell[note_ind]][3:0] == 0) begin
//                                 image_addr <= 19874;
//                             end else begin
//                                 image_addr <= (note_memory[note_ind][start_staff_cell[note_ind]][3:0] < 5)? // up or down circle
//                                               (0 + y_counter) * 265 + (0 + x_counter) : (0 + y_counter) * 265 + (5 + x_counter);
//                             end
//                             x_counter <= (x_counter + 1 == 5)? 0 : x_counter + 1;
//                             y_counter <= (x_counter + 1 == 5)? (y_counter + 1 == 7)? 0 : y_counter + 1 : y_counter;
//                             note_ind <= (y_counter + 1 == 7 && x_counter + 1 == 5)? (note_ind + 1 == 5)? 0 : note_ind + 1 : note_ind;
//                             storing_state <= (y_counter + 1 == 7 && x_counter + 1 == 5 && note_ind + 1 == 5)? IDLE : STORING;
//                         end
//                         EIGHTH: begin
//                             // check if note is sharp
//                             if ((note_memory[note_ind][start_staff_cell[note_ind]][7:4] == 1) || 
//                             (note_memory[note_ind][start_staff_cell[note_ind]][7:4] == 3) || 
//                             (note_memory[note_ind][start_staff_cell[note_ind]][7:4] == 6) || 
//                             (note_memory[note_ind][start_staff_cell[note_ind]][7:4] == 8) || 
//                             (note_memory[note_ind][start_staff_cell[note_ind]][7:4] == 10)) 
//                             begin
//                                 image_addr <= (7 + y_counter) * 265 + (10 + x_counter);
//                             end else if (note_memory[note_ind][start_staff_cell[note_ind]][7:4] == 0 && note_memory[note_ind][start_staff_cell[note_ind]][3:0] == 0) begin
//                                 image_addr <= 19874;
//                             end else begin
//                                 image_addr <= (0 + y_counter) * 265 + (10 + x_counter);
//                             end
//                             x_counter <= (y_counter == 6)? (x_counter + 1 == 10)? 0 : x_counter + 1 : x_counter;
//                             note_ind <= (y_counter + 1 == 7 && x_counter + 1 == 10)? (note_ind + 1 == 5)? 0 : note_ind + 1 : note_ind;
//                             storing_state <= (y_counter + 1 == 7 && x_counter + 1 == 10 && note_ind + 1 == 5)? IDLE : STORING;
//                         end
//                         DOTTED_EIGHTH: begin
//                             // check if note is sharp
//                             if ((note_memory[note_ind][start_staff_cell[note_ind]][7:4] == 1) || 
//                             (note_memory[note_ind][start_staff_cell[note_ind]][7:4] == 3) || 
//                             (note_memory[note_ind][start_staff_cell[note_ind]][7:4] == 6) || 
//                             (note_memory[note_ind][start_staff_cell[note_ind]][7:4] == 8) || 
//                             (note_memory[note_ind][start_staff_cell[note_ind]][7:4] == 10)) 
//                             begin
//                                 image_addr <= (7 + y_counter) * 265 + (20 + x_counter);
//                             end else if (note_memory[note_ind][start_staff_cell[note_ind]][7:4] == 0 && note_memory[note_ind][start_staff_cell[note_ind]][3:0] == 0) begin
//                                 image_addr <= 19874;
//                             end else begin
//                                 image_addr <= (0 + y_counter) * 265 + (20 + x_counter);
//                             end
//                             x_counter <= (y_counter == 6)? (x_counter + 1 == 15)? 0 : x_counter + 1 : x_counter;
//                             note_ind <= (y_counter + 1 == 7 && x_counter + 1 == 15)? (note_ind + 1 == 5)? 0 : note_ind + 1 : note_ind;
//                             storing_state <= (y_counter + 1 == 7 && x_counter + 1 == 15 && note_ind + 1 == 5)? IDLE : STORING;
//                         end
//                         QUARTER: begin
//                             // check if note is sharp
//                             if ((note_memory[note_ind][start_staff_cell[note_ind]][7:4] == 1) || 
//                             (note_memory[note_ind][start_staff_cell[note_ind]][7:4] == 3) || 
//                             (note_memory[note_ind][start_staff_cell[note_ind]][7:4] == 6) || 
//                             (note_memory[note_ind][start_staff_cell[note_ind]][7:4] == 8) || 
//                             (note_memory[note_ind][start_staff_cell[note_ind]][7:4] == 10)) 
//                             begin
//                                 image_addr <= (7 + y_counter) * 265 + (35 + x_counter);
//                             end else if (note_memory[note_ind][start_staff_cell[note_ind]][7:4] == 0 && note_memory[note_ind][start_staff_cell[note_ind]][3:0] == 0) begin
//                                 image_addr <= 19874;
//                             end else begin
//                                 image_addr <= (0 + y_counter) * 265 + (35 + x_counter);
//                             end
//                             x_counter <= (y_counter == 6)? (x_counter + 1 == 20)? 0 : x_counter + 1 : x_counter;
//                             note_ind <= (y_counter + 1 == 7 && x_counter + 1 == 20)? (note_ind + 1 == 5)? 0 : note_ind + 1 : note_ind;
//                             storing_state <= (y_counter + 1 == 7 && x_counter + 1 == 20 && note_ind + 1 == 5)? IDLE : STORING;
//                         end
//                         DOTTED_QUARTER: begin
//                             // check if note is sharp
//                             if ((note_memory[note_ind][start_staff_cell[note_ind]][7:4] == 1) || 
//                             (note_memory[note_ind][start_staff_cell[note_ind]][7:4] == 3) || 
//                             (note_memory[note_ind][start_staff_cell[note_ind]][7:4] == 6) || 
//                             (note_memory[note_ind][start_staff_cell[note_ind]][7:4] == 8) || 
//                             (note_memory[note_ind][start_staff_cell[note_ind]][7:4] == 10)) 
//                             begin
//                                 image_addr <= (7 + y_counter) * 265 + (55 + x_counter);
//                             end else if (note_memory[note_ind][start_staff_cell[note_ind]][7:4] == 0 && note_memory[note_ind][start_staff_cell[note_ind]][3:0] == 0) begin
//                                 image_addr <= 19874;
//                             end else begin
//                                 image_addr <= (0 + y_counter) * 265 + (55 + x_counter);
//                             end
//                             x_counter <= (y_counter == 6)? (x_counter + 1 == 30)? 0 : x_counter + 1 : x_counter;
//                             note_ind <= (y_counter + 1 == 7 && x_counter + 1 == 30)? (note_ind + 1 == 5)? 0 : note_ind + 1 : note_ind;
//                             storing_state <= (y_counter + 1 == 7 && x_counter + 1 == 30 && note_ind + 1 == 5)? IDLE : STORING;
//                         end
//                         HALF: begin
//                             // check if note is sharp
//                             if ((note_memory[note_ind][start_staff_cell[note_ind]][7:4] == 1) || 
//                             (note_memory[note_ind][start_staff_cell[note_ind]][7:4] == 3) || 
//                             (note_memory[note_ind][start_staff_cell[note_ind]][7:4] == 6) || 
//                             (note_memory[note_ind][start_staff_cell[note_ind]][7:4] == 8) || 
//                             (note_memory[note_ind][start_staff_cell[note_ind]][7:4] == 10)) 
//                             begin
//                                 image_addr <= (7 + y_counter) * 265 + (85 + x_counter);
//                             end else if (note_memory[note_ind][start_staff_cell[note_ind]][7:4] == 0 && note_memory[note_ind][start_staff_cell[note_ind]][3:0] == 0) begin
//                                 image_addr <= 19874;
//                             end else begin
//                                 image_addr <= (0 + y_counter) * 265 + (85 + x_counter);
//                             end
//                             x_counter <= (y_counter == 6)? (x_counter + 1 == 40)? 0 : x_counter +  1: x_counter;
//                             note_ind <= (y_counter + 1 == 7 && x_counter + 1 == 40)? (note_ind + 1 == 5)? 0 : note_ind + 1 : note_ind;
//                             storing_state <= (y_counter + 1 == 7 && x_counter + 1 == 40 && note_ind + 1 == 5)? IDLE : STORING;
//                         end
//                         DOTTED_HALF: begin
//                             // check if note is sharp
//                             if ((note_memory[note_ind][start_staff_cell[note_ind]][7:4] == 1) || 
//                             (note_memory[note_ind][start_staff_cell[note_ind]][7:4] == 3) || 
//                             (note_memory[note_ind][start_staff_cell[note_ind]][7:4] == 6) || 
//                             (note_memory[note_ind][start_staff_cell[note_ind]][7:4] == 8) || 
//                             (note_memory[note_ind][start_staff_cell[note_ind]][7:4] == 10)) 
//                             begin
//                                 image_addr <= (7 + y_counter) * 265 + (125 + x_counter);
//                             end else if (note_memory[note_ind][start_staff_cell[note_ind]][7:4] == 0 && note_memory[note_ind][start_staff_cell[note_ind]][3:0] == 0) begin
//                                 image_addr <= 19874;
//                             end else begin
//                                 image_addr <= (0 + y_counter) * 265 + (125 + x_counter);
//                             end
//                             x_counter <= (y_counter == 6)? (x_counter + 1 == 60)? 0 : x_counter + 1 : x_counter;
//                             note_ind <= (y_counter + 1 == 7 && x_counter + 1 == 60)? (note_ind + 1 == 5)? 0 : note_ind + 1 : note_ind;
//                             storing_state <= (y_counter + 1 == 7 && x_counter + 1 == 60 && note_ind + 1 == 5)? IDLE : STORING;
//                         end
//                         WHOLE: begin
//                             // check if note is sharp
//                             if ((note_memory[note_ind][start_staff_cell[note_ind]][7:4] == 1) || 
//                             (note_memory[note_ind][start_staff_cell[note_ind]][7:4] == 3) || 
//                             (note_memory[note_ind][start_staff_cell[note_ind]][7:4] == 6) || 
//                             (note_memory[note_ind][start_staff_cell[note_ind]][7:4] == 8) || 
//                             (note_memory[note_ind][start_staff_cell[note_ind]][7:4] == 10)) 
//                             begin
//                                 image_addr <= (7 + y_counter) * 265 + (185 + x_counter);
//                             end else if (note_memory[note_ind][start_staff_cell[note_ind]][7:4] == 0 && note_memory[note_ind][start_staff_cell[note_ind]][3:0] == 0) begin
//                                 image_addr <= 19874;
//                             end else begin
//                                 image_addr <= (0 + y_counter) * 265 + (185 + x_counter);
//                             end
//                             x_counter <= (y_counter == 6)? (x_counter + 1 == 80)? 0 : x_counter + 1 : x_counter;
//                             note_ind <= (y_counter + 1 == 7 && x_counter + 1 == 80)? (note_ind + 1 == 5)? 0 : note_ind + 1 : note_ind;
//                             storing_state <= (y_counter + 1 == 7 && x_counter + 1 == 80 && note_ind + 1 == 5)? IDLE : STORING;
//                         end
//                     endcase
//                 end else begin
//                     check3 <= 3;
//                     check2 <= 0;
//                     check1 <= 0;
//                 end

//             end
//         endcase
//     end
// end

//________________________________________________________________________
// PIXEL EDITING]][[]]}


logic [14:0] image_addr; // 15 bit addresses
logic [7:0] image_mem; 

xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(8),                       // Specify RAM data width
    .RAM_DEPTH(19875),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    .INIT_FILE(`FPATH(image.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) image_BROM (
    .addra(image_addr),     // Address bus, width determined from RAM_DEPTH
    .dina(0),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk_in),       // Clock
    .wea(0),         // Write enable
    .ena(1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst_in),       // Output reset (does not affect memory contents)
    .regcea(1),   // Output register enable
    .douta(image_mem)      // RAM output data, width determined from RAM_WIDTH
  );


assign mem_out = {8'b0, image_mem};

endmodule

`default_nettype wire
