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
    input wire  [31:0] durations_in[4:0],
    output logic [15:0] addr_out,
    output logic [15:0] mem_out,
    output logic valid_note_out,
    output logic [11:0] note_memory [4:0][63:0],
    output logic [31:0] sixteenth_metronome,
    output logic [5:0] current_staff_cell,
    output logic [5:0] current_staff_cell_buf,
    output logic [3:0] storing_state_out_test,
    output logic [3:0] storing_state_out,
    output logic [3:0] note_rhythms [4:0],
    output logic [4:0][5:0] start_staff_cell,
    output logic [11:0] detected_note [4:0],
    output logic [12:0] num_pixels,
    output logic [3:0] check,
    output logic valid_staff_record_out

);

assign storing_state_out_test = note_memory[0][start_staff_cell[0]][11:8];

logic [4:0][7:0] notes_in_test;
logic [4:0][31:0] durations_in_test;
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

// logic [5:0] current_staff_cell_buf;

always_ff @(posedge clk_in) begin
    if (rst_in) begin
        sixteenth_metronome <= 1_499_999_999;
        current_staff_cell <= 0;
        valid_staff_record_out <= 0;
    end else begin
        sixteenth_metronome <= (storing_state != INIT)?(sixteenth_metronome + (bpm >> 2) >= 1_500_000_000)? 0 : sixteenth_metronome + (bpm >> 2): 0;
        current_staff_cell <= (storing_state != INIT)? (sixteenth_metronome + (bpm >> 2) >= 1_500_000_000)? (current_staff_cell + 1 == 64)? 0 : current_staff_cell + 1 : current_staff_cell:0;
        current_staff_cell_buf <= current_staff_cell;
        valid_staff_record_out <= (current_staff_cell)? 1:0;
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
localparam [3:0] WHOLE = 15;
localparam [3:0] NULL = 13;
// typedef enum logic [3:0] {  EIGHTH = 2, DOTTED_EIGHTH = 3, QUARTER = 4, DOTTED_QUARTER = 6, HALF = 8, DOTTED_HALF = 12, WHOLE = 0, NULL = 13} note_rhythm;
logic [3:0] note_rhythm_buffer[4:0] ;



logic [4:0][6:0] note_width, note_width_buf1, note_width_buf2, note_width_buf3;
logic [4:0][2:0] sharp_shift, sharp_shift_buf1, sharp_shift_buf2, sharp_shift_buf3;
logic [4:0][7:0] rhythm_shift, rhythm_shift_buf1, rhythm_shift_buf2, rhythm_shift_buf3;

assign sharp_shift[0] = (  (note_memory[0][start_staff_cell[0]][7:4] == 1) || 
                        (note_memory[0][start_staff_cell[0]][7:4] == 3) || 
                        (note_memory[0][start_staff_cell[0]][7:4] == 6) || 
                        (note_memory[0][start_staff_cell[0]][7:4] == 8) || 
                        (note_memory[0][start_staff_cell[0]][7:4] == 10)) ? 7 : 0;

always_comb begin
    for (int i = 0; i < 5; i++) begin
        //(3/8)*CYCLES_PER_BEAT) = 4_500_000_000
        if ((cycles_in[i] > 0) && (cycles_in[i] < 64'd1_300_000_000)) begin
            note_rhythms[i] = SIXTEENTH; // 5 bit dot
            note_width[i] = 5;
            rhythm_shift[i] = (note_memory[0][current_staff_cell[0]][3:0] < 5)? 0 : 5;
            // check[i] = 0;
        // (7/16)*CYCLES_PER_BEAT = 5_250_000_000
        end else if ((cycles_in[i] >= 64'd1_300_000_000) && (cycles_in[i] < 64'd2_800_000_000)) begin
            note_rhythms[i] = EIGHTH; // 6 bit dot
            note_width[i] = 10;
            rhythm_shift[i] = 10;
            // check[i] = 1;
        //(11/16)*CYCLES_PER_BEAT = 8_250_000_000
        end else if ((cycles_in[i] >= 64'd2_800_000_000) && (cycles_in[i] < 64'd4_300_000_000)) begin
            note_rhythms[i] = DOTTED_EIGHTH; // 6 bit dot
            note_width[i] = 15;
            rhythm_shift[i] = 20;
            // check[i] = 2;
        //(5/4)*CYCLES_PER_BEAT = 15_000_000_000
        end else if ((cycles_in[i] >= 64'd4_300_000_000) && (cycles_in[i] < 64'd5_800_000_000)) begin
            note_rhythms[i] = QUARTER; // 7 bit dot
            note_width[i] = 20;
            rhythm_shift[i] = 35;
            // check[i] = ((11/16)*CYCLES_PER_BEAT);
        // (7/4)*CYCLES_PER_BEAT = 21_000_000_000
        end else if ((cycles_in[i] >= 64'd5_800_000_000) && (cycles_in[i] < 64'd8_800_000_000)) begin
            note_rhythms[i] = DOTTED_QUARTER;
            note_width[i] = 30;
            rhythm_shift[i] = 55;
             // check[i] = 4;
        // (5/2)*CYCLES_PER_BEAT = 30_000_000_000
        end else if ((cycles_in[i] >= 64'd8_800_000_000) && (cycles_in[i] < 64'd11_800_000_000)) begin
            note_rhythms[i] = HALF;
            note_width[i] = 40;
            rhythm_shift[i] = 85;
            // check[i] = 5;
        //(7/2)*CYCLES_PER_BEAT = 42_000_000_000
        end else if ((cycles_in[i] >= 64'd11_800_000_000) && (cycles_in[i] < 64'd17_800_000_000)) begin
            note_rhythms[i] = DOTTED_HALF;
            note_width[i] = 60;
            rhythm_shift[i] = 125;
            // check[i] = 6;
        //4*CYCLES_PER_BEAT = 48_000_000_000
        end else if ((cycles_in[i] >= 64'd17_800_000_000) && (cycles_in[i] < 64'd24_000_000_000)) begin
            note_rhythms[i] = WHOLE; // 9 bit dot
            note_width[i] = 80;
            rhythm_shift[i] = 185;
            // check[i] = 7;
        end else begin
            note_rhythms[i] = 4'b0;
            note_width[i] =8'b0;
            rhythm_shift[i] = 0;
        end
    end
end

// find y based on pitch and octave!
always_comb begin
    for (int i = 0; i < 5; i++) begin
        case (notes_in[i][7:4])
            0,1: y_dot[i] = 0 + 6*7*(8 - notes_in[i][3:0]);  // C; 7 notes per octave, 6 vertical pixels per note
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

logic [4:0][7:0] y_dot, y_dot_buf;
logic [7:0] y_stem, y_stem_buf;

// find the highest/lowest note in the chord
logic [7:0] highest_note, lowest_note, extreme_note;
always_ff @(posedge clk_in) begin
    if (rst_in) begin
        highest_note <= 8'h00;
        lowest_note <= 8'h08;
    end else begin
        for (int i = 0; i < 5; i ++) begin
            if (notes_in[i] != 8'hFF) begin
                highest_note <= (notes_in[i][7:4] + 12*notes_in[i][3:0] > highest_note[7:4] + 12 * highest_note[3:0])? notes_in[i] : highest_note;
                lowest_note <= (notes_in[i][7:4] + 12*notes_in[i][3:0] < lowest_note[7:4] + 12 * lowest_note[3:0])? notes_in[i] : lowest_note;
            end
        end
        if ((127 - highest_note[7:4] + 12 * highest_note[3:0]) > lowest_note[7:4] + 12 * lowest_note[3:0]) begin
            extreme_note <= highest_note;
        end else begin
            extreme_note <= lowest_note;
      end
    end
end


always_comb begin
    case (extreme_note[7:4])
        0,1: y_stem = 0 + 6*7*(8 - extreme_note[3:0]);  // C; 7 notes per octave, 6 vertical pixels per note
        2,3: y_stem = 18 + 6*7*(8 - extreme_note[3:0]);  // D sharp; 7 notes per octave, 6 pixels per note
        4: y_stem = 15 + 6*7*(8 - extreme_note[3:0]);  // E; 7 notes per octave, 6 pixels per note
        5,6: y_stem = 12 + 6*7*(8 - extreme_note[3:0]);  // F; 7 notes per octave, 6 pixels per note  
        7,8: y_stem = 9 + 6*7*(8 - extreme_note[3:0]);  // G; 7 notes per octave, 6 pixels per note        
        9,10: y_stem = 6 + 6*7*(8 - extreme_note[3:0]);  // A; 7 notes per octave, 6 pixels per note          
        11: y_stem = 3 + 6*7*(8 - extreme_note[3:0]);  // B; 7 notes per octave, 6 pixels per note        
        default: y_stem = 150;
    endcase
end

//________________________________________________________________________
// STORING PIXELS OF CORRESPONDING NOTES
// this all needs to happen within 3_000_000_000 cycles

localparam STAFF_SHIFT = 66; // top of staff is 141 when not shifted; want to be at 75: 141 - 66 = 75
localparam STAFF_HEIGHT = 35;
enum logic [4:0] {INIT = 0, IDLE = 1, NOTE = 2, REST = 3, STEM = 4, SPLIT_NOTE = 5} storing_state;

assign storing_state_out = storing_state;

logic [4:0][8:0] x_start_note, x_start_stem;
logic [4:0] [7:0] y_start_note, y_start_stem; // c0 -> c8 leads to 336 possible y locations
logic [8:0] x_counter; // can go up to 80 for notes
logic [7:0] y_counter, y_out, y_out1, y_out2; // can go up to 7 for notes


logic [15:0] addr_buf1, addr_buf2; 
logic valid_note_buf1, valid_note_buf2;   

logic already_drawn;
logic [2:0] rest_measures;
logic [31:0] detected_refresh;

always_ff @(posedge clk_in) begin
    // detected_refresh <= (if you detect a note)? 0: detected_refresh + (bpm >>2);
    // if detected refresh is under 1_500_000_000, you detected note must remain nothing; only after that can you pick up the next detected note
    // if you detect a note and the refrash is over 1_500_000_000? then you can set detected note. restart detected refresh
    // otherwise leave detected note as nothing and increment detected refresh
    if (rst_in) begin
        detected_note[0] <= 12'h0FF;
        detected_refresh <= 0;
    end else if (detected_refresh >= 64'd1_300_000_000 && notes_in[0] != 8'hFF) begin
        detected_note[0] <= (detected_note[0][7:0] != {notes_in[0]})? {note_rhythms[0], notes_in[0]} : detected_note[0];
        detected_refresh <= 0;
    end else begin
        detected_note[0] <= 12'h0FF;
        detected_refresh <= (detected_refresh > 64'd1_300_000_000)? detected_refresh:detected_refresh + (bpm >>2);
    end
    // end else if (current_staff_cell != current_staff_cell_buf) begin//(sixteenth_metronome == 2*(bpm >> 2)) begin
    //     detected_note[0] <= 12'h0FF;
    // end else begin//if (sixteenth_metronome <= (bpm >> 2) || (sixteenth_metronome >= 3*(bpm >> 2) && sixteenth_metronome + (bpm >> 2) < 1_500_000_000)) begin
    //     detected_note[0] <= (detected_note[0][7:0] != {notes_in[0]})? {note_rhythms[0], notes_in[0]} : detected_note[0];
    // end
    // keep track of any changes between sixteenth_metronome <= (bpm >> 2) and sixteenth_metronome + (bpm >> 2) >= 1_500_000_000
    sharp_shift_buf1 <= sharp_shift;
    note_width_buf1 <= note_width;
    rhythm_shift_buf1 <= rhythm_shift;
    sharp_shift_buf2 <= sharp_shift_buf1;
    note_width_buf2 <= note_width_buf1;
    rhythm_shift_buf2 <= rhythm_shift_buf1;
    sharp_shift_buf3 <= sharp_shift_buf2;
    note_width_buf3 <= note_width_buf2;
    rhythm_shift_buf3 <= rhythm_shift_buf2;
    y_dot_buf <= y_dot;
    y_stem_buf <= y_stem;
end

always_ff @(posedge clk_in) begin
    if (rst_in) begin
        storing_state <= INIT;
        start_staff_cell <= 0;
        
        x_start_note <= 0;
        y_start_note <= 0;        
        x_start_stem <= 0;
        y_start_stem <= 0;
        x_counter <= 0;
        y_counter <= 0;

        // y_out <= 0;
        // y_out1 <= 0;
        // y_out2 <= 0;

        for (int i = 0; i < 5; i ++) begin
            for (int j = 0; j < 64; j++) begin
            note_memory[i][j] <= (j == 0 || j == 80 || j == 160 || j == 240)? 12'hFFF : 12'hDFF; // F is whole rest, D is null value in memory
            end
        end

        image_addr <= 0;
        addr_out <= 0;   
        addr_buf1 <= 0;
        addr_buf2 <= 0;
        
        valid_note_out <= 0;   
        valid_note_buf1 <= 0;   
        valid_note_buf2 <= 0;   
        // check <= 0;
        already_drawn <= 0;
        rest_measures <= 0;
        // note_change_valid <= 0;
        // note_ind <= 0;
    end else begin
        case (storing_state) // all happens within the same current_staff_cell, hopefully
            INIT: begin
                image_addr <= 9;
                x_counter <= (x_counter == 319)? 0: x_counter + 1;
                y_counter <= (x_counter == 319)? (y_counter == 179)? 0: y_counter + 1 : y_counter;
                addr_buf1 <= (y_counter) * 320 + (x_counter);
                addr_buf2 <= addr_buf1;
                addr_out <= addr_buf2;   
                storing_state <= (x_counter == 319 && y_counter == 179)? REST : INIT;
                valid_note_buf1 <= 1;
                valid_note_buf2 <= valid_note_buf1;
                valid_note_out <= valid_note_buf2;
            end
            REST: begin
                rest_measures <= (x_counter == (79) && y_counter == 24)? (rest_measures == 4)? 0 : rest_measures + 1 : rest_measures;
                x_counter <= (x_counter == 79)? 0: x_counter + 1;
                y_counter <= (x_counter == 79)? (y_counter == 24)? 0: y_counter + 1 : y_counter;

                image_addr <= (y_counter + 50) * 265 + (x_counter + 185); // white pixel at address 19874 - white out if no note
                addr_buf1 <= (75 + y_counter) * 320 + (80*rest_measures + x_counter);
                addr_buf2 <= addr_buf1;
                addr_out <= addr_buf2;
                
                valid_note_buf1 <= 1;
                valid_note_buf2 <= valid_note_buf1;
                valid_note_out <= valid_note_buf2;

                y_out <= 75 + y_counter;
                y_out1 <= y_out;
                y_out2 <= y_out1;

                storing_state <= (rest_measures == 4)? IDLE : REST;
            end
            IDLE: begin
                check[0] <= detected_note[0][11:8] == SIXTEENTH;
                check[1] <= detected_note[0][11:8] != note_memory[0][start_staff_cell[0]][11:8];
                check[2] <= already_drawn; //sixteenth_metronome <= (bpm >> 2);
                check[3] <= detected_note[0][7:0] != 8'hFF;
                
                already_drawn <= (current_staff_cell != current_staff_cell_buf)? 0: already_drawn;
                // if there is a note input, want to do something
                if (detected_note[0][7:0] != 8'hFF && detected_note[0][11:8] != 0) begin
                    num_pixels <= 0;
                    // storing_state <= (notes_in[0][7:0] != 8'hFF)? NOTE : REST;
                    // If current note rhythm is not the same as the one stored at the start

                    // if there is a change in detected note, AND in this cell cycle nothing has been drawn yet
                    if (((detected_note[0][11:8] != (note_memory[0][start_staff_cell[0]][11:8]) && detected_note[0][11:8] != SIXTEENTH) ||
                        (detected_note[0][11:8] != (note_memory[0][current_staff_cell][11:8]) && detected_note[0][11:8] == SIXTEENTH)) && already_drawn == 0) begin // && already_drawn == 0
                        storing_state <= NOTE;

                        // If new note is SIXTEENTH, its the beginning of new note
                        // This occurs if note changes, or if it turns on/off, or if a new measure starts
                        start_staff_cell[0] <= (detected_note[0][11:8] == SIXTEENTH)? current_staff_cell : start_staff_cell[0];
                        x_start_note[0] <= (detected_note[0][11:8] == SIXTEENTH)? current_staff_cell * 5 : start_staff_cell[0] * 5;
                        y_start_note[0] <= y_dot_buf[0] - STAFF_SHIFT;

                        if (detected_note[0][11:8] == SIXTEENTH) begin 
                            note_memory[0][current_staff_cell][11:8] <= detected_note[0][11:8];
                            note_memory[0][current_staff_cell][7:0] <= detected_note[0][7:0];
                        // If just extending duration of any note
                        end else begin 
                            note_memory[0][start_staff_cell[0]][11:8] <= detected_note[0][11:8];
                            note_memory[0][start_staff_cell[0]][7:0] <= detected_note[0][7:0]; // store start to be able to break nulls
                            note_memory[0][current_staff_cell_buf][11:8] <= NULL;
                        end
                    // else you are waiting for either something to change, or for the next cell
                    end else begin
                        // storing_state <= TRACK;
                        // start_staff_cell[0] <= current_staff_cell;
                    end
                // else, no input note, don't really do anything
                end else begin
                    // start_staff_cell[0] <= current_staff_cell;
                end
                valid_note_buf1 <= 0;
                valid_note_buf2 <= valid_note_buf1;
                valid_note_out <= valid_note_buf2;
                addr_buf2 <= addr_buf1;
                addr_out <= addr_buf2;
            end
            NOTE: begin
                // already_drawn <= 1;
                // num_pixels <= num_pixels + 1;
                x_counter <= (x_counter == note_width_buf2[0] - 1)? 0: x_counter + 1;
                y_counter <= (x_counter == note_width_buf2[0] - 1)? (y_counter == 6)? 0: y_counter + 1 : y_counter;

                image_addr <= (y_counter + sharp_shift_buf2[0]) * 265 + (x_counter + rhythm_shift_buf2[0]); // white pixel at address 19874 - white out if no note
                addr_buf1 <= ((x_start_note[0] + x_counter >= 320)? y_start_note[0] + y_counter-1:y_start_note[0] + y_counter) * 320 + (x_start_note[0] + x_counter);
                addr_buf2 <= addr_buf1;
                addr_out <= addr_buf2;
                
                storing_state <= (x_counter == (note_width_buf2[0] - 1) && y_counter == 6)? STEM : NOTE;
                
                valid_note_buf1 <= 1;
                valid_note_buf2 <= valid_note_buf1;
                valid_note_out <= valid_note_buf2;
                
                y_out <= y_start_note[0] + y_counter;
                y_out1 <= y_out;
                y_out2 <= y_out1;

                y_start_stem[0] <= (note_memory[0][start_staff_cell[0]][3:0] < 5)? y_stem_buf - 18 - STAFF_SHIFT : y_stem_buf + 7 - STAFF_SHIFT;
                x_start_stem[0] <= x_start_note[0];

            end
            STEM: begin
                // already_drawn <= 1;
                // num_pixels <= num_pixels + 1;
                x_counter <= (x_counter == note_width_buf3[0] - 1)? 0: x_counter + 1;
                y_counter <= (x_counter == note_width_buf3[0] - 1)? (y_counter == 17)? 0: y_counter + 1 : y_counter;
                // make a second x y counter for the entire hdmi screen separately; above is counter for image 
                image_addr <= (note_memory[0][start_staff_cell[0]][3:0] < 5)? (14 + y_counter) * 265 + (x_counter + rhythm_shift_buf3[0]) :
                                                                              (32 + y_counter) * 265 + (x_counter + rhythm_shift_buf3[0]); // white pixel at address 19874 - white out if no note
                addr_buf1 <= ((x_start_stem[0] + x_counter >= 320)? y_start_stem[0] + y_counter - 1 : y_start_stem[0] + y_counter) * 320 + (x_start_stem[0] + x_counter);
                addr_buf2 <= addr_buf1;
                addr_out <= addr_buf2;
                
                storing_state <= (x_counter == (note_width_buf3[0] - 1) && y_counter == 17)? IDLE : STEM;
                
                valid_note_buf1 <= 1;
                valid_note_buf2 <= valid_note_buf1;
                valid_note_out <= valid_note_buf2;
                
                y_out <= y_start_stem[0] + y_counter;
                y_out1 <= y_out;
                y_out2 <= y_out1;
            end
        endcase
    end
end

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


assign mem_out = ((y_out2 == 75 || y_out2 == 81 || y_out2 == 87 || y_out2 == 93 || y_out2 == 99) && (image_mem >= 8'h94))? 16'h0094 : {8'b0, image_mem};
// assign mem_out = image_mem;

endmodule

`default_nettype wire
