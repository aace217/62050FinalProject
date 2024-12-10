`timescale 1ns / 1ps
`default_nettype none

module note_storing_position(
    input wire rst_in,
    input wire clk_in,
    input wire [7:0] bpm,
    input wire  [7:0] notes_in [4:0],
    input wire  [31:0] durations_in[4:0],
    output logic [5:0] current_staff_cell,
    
    output logic [4:0][6:0] note_width,
    output logic [4:0][2:0] sharp_shift,
    output logic [4:0][7:0] rhythm_shift,
    
    output logic [3:0] note_rhythms [4:0],
    output logic [3:0] notes_out [4:0],
    
    output logic [4:0][7:0] y_dot_out,
    output logic [7:0] y_stem
);

//________________________________________________________________________
// SETTING UP METRONOME, BPM ON 16th NOTE 

always_ff @(posedge clk_in) begin
    if (rst_in) begin
        sixteenth_metronome <= 1_499_999_999;
        current_staff_cell <= 0;
    end else begin
        sixteenth_metronome <= (sixteenth_metronome + (bpm >> 2) >= 1_500_000_000)? 0 : sixteenth_metronome + (bpm >> 2);
        current_staff_cell <= (sixteenth_metronome + (bpm >> 2) >= 1_500_000_000)? (current_staff_cell == 63)? 0 : current_staff_cell + 1 : current_staff_cell;
    end
end

//________________________________________________________________________
// GETTING X POSITION AND RHYTHM OF INPUTTED NOTES

localparam CYCLES_PER_BEAT = 60*100_000_000;
localparam [3:0] SIXTEENTH = 1;
localparam [3:0] EIGHTH = 2;
localparam [3:0] DOTTED_EIGHTH = 3;
localparam [3:0] QUARTER = 4;
localparam [3:0] DOTTED_QUARTER = 6;
localparam [3:0] HALF = 8;
localparam [3:0] DOTTED_HALF = 12;
localparam [3:0] WHOLE = 15;
localparam [3:0] NULL = 13;

// max cycles in is max duration, 1_200_000_000 cycles times its bpm 40 which is 48_000_000_000
// basically 60*200_000_000 cycles per beat * 4 quarter notes
logic [4:0][35:0] cycles_in;
always_comb begin
    for (int i = 0; i < 5; i++) begin
        cycles_in[i] = durations_in[i]*(bpm >> 2);
    end
end

always_ff @(posedge clk_in) begin
    if (rst_in) begin
        for (int i = 0; i < 5; i++) begin
            sharp_shift[i] <= 0;
            note_rhythms[i] <= 0; // 5 bit dot
            note_width[i] <= 0;
            rhythm_shift[i] <= 0;

        end
    end else begin
        for (int i = 0; i < 5; i++) begin
            notes_out <= notes_in;
            sharp_shift[i] <= ((notes_in[7:4] == 1) || (notes_in[7:4] == 3) || 
                                (notes_in[7:4] == 6) || (notes_in[7:4] == 8) || 
                                (notes_in[7:4] == 10)) ? 7 : 0;

            if ((cycles_in[i] > 50_000) && (cycles_in[i] < 64'd1_300_000_000)) begin
                note_rhythms[i] <= SIXTEENTH; // 5 bit dot
                note_width[i] <= 5;
                rhythm_shift[i] <= (note_memory[0][current_staff_cell[0]][3:0] < 5)? 0 : 5;
            end else if ((cycles_in[i] >= 64'd1_300_000_000) && (cycles_in[i] < 64'd2_800_000_000)) begin
                note_rhythms[i] <= EIGHTH; // 6 bit dot
                note_width[i] <= 10;
                rhythm_shift[i] <= 10;
            end else if ((cycles_in[i] >= 64'd2_800_000_000) && (cycles_in[i] < 64'd4_300_000_000)) begin
                note_rhythms[i] <= DOTTED_EIGHTH; // 6 bit dot
                note_width[i] <= 15;
                rhythm_shift[i] <= 20;
            end else if ((cycles_in[i] >= 64'd4_300_000_000) && (cycles_in[i] < 64'd5_800_000_000)) begin
                note_rhythms[i] <= QUARTER; // 7 bit dot
                note_width[i] <= 20;
                rhythm_shift[i] <= 35;
            end else if ((cycles_in[i] >= 64'd5_800_000_000) && (cycles_in[i] < 64'd8_800_000_000)) begin
                note_rhythms[i] <= DOTTED_QUARTER;
                note_width[i] <= 30;
                rhythm_shift[i] <= 55;
            end else if ((cycles_in[i] >= 64'd8_800_000_000) && (cycles_in[i] < 64'd11_800_000_000)) begin
                note_rhythms[i] <= HALF;
                note_width[i] <= 40;
                rhythm_shift[i] <= 85;
            end else if ((cycles_in[i] >= 64'd11_800_000_000) && (cycles_in[i] < 64'd17_800_000_000)) begin
                note_rhythms[i] <= DOTTED_HALF;
                note_width[i] <= 60;
                rhythm_shift[i] <= 125;
            end else if ((cycles_in[i] >= 64'd17_800_000_000) && (cycles_in[i] < 64'd24_000_000_000)) begin
                note_rhythms[i] <= WHOLE; // 9 bit dot
                note_width[i] <= 80;
                rhythm_shift[i] <= 185;
            end else begin
                note_rhythms[i] <= 4'b0;
                note_width[i] <= 8'b0;
                rhythm_shift[i] <= 0;
            end
        end
    end
end
 

// ___________________________________________________________________________________ 
// GET Y POSITION OF INPUT NOTE + STEM

logic [4:0][7:0] y_dot, y_highest, y_lowest;

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

    y_highest = 8'h00;
    y_lowest = 8'hFF;
    for (int i = 0; i < 5; i ++) begin
        if (notes_in[i] != 8'hFF) begin
            
        end
    end
end

always_ff @(posedge clk_in) begin
    if (rst_in) begin
        y_dot_out <= 0;
        y_stem <= 0;
    end else begin
        y_dot_out <= y_dot;

    end

end



// // find the highest/lowest note in the chord
// logic [7:0] highest_note, lowest_note, extreme_note;
// always_ff @(posedge clk_in) begin
//     if (rst_in) begin
//         highest_note <= 8'h00;
//         lowest_note <= 8'h08;
//     end else begin
//         for (int i = 0; i < 5; i ++) begin
//             if (notes_in[i] != 8'hFF) begin
//                 highest_note <= (notes_in[i][7:4] + 12*notes_in[i][3:0] > highest_note[7:4] + 12 * highest_note[3:0])? notes_in[i] : highest_note;
//                 lowest_note <= (notes_in[i][7:4] + 12*notes_in[i][3:0] < lowest_note[7:4] + 12 * lowest_note[3:0])? notes_in[i] : lowest_note;
//             end
//         end
//         if ((127 - highest_note[7:4] + 12 * highest_note[3:0]) > lowest_note[7:4] + 12 * lowest_note[3:0]) begin
//             extreme_note <= highest_note;
//         end else begin
//             extreme_note <= lowest_note;
//       end
//     end
// end

// always_comb begin
//     case (extreme_note[7:4])
//         0,1: y_stem = 0 + 6*7*(8 - extreme_note[3:0]);  // C; 7 notes per octave, 6 vertical pixels per note
//         2,3: y_stem  = 18 + 6*7*(8 - extreme_note[3:0]);  // D sharp; 7 notes per octave, 6 pixels per note
//         4: y_stem = 15 + 6*7*(8 - extreme_note[3:0]);  // E; 7 notes per octave, 6 pixels per note
//         5,6: y_stem = 12 + 6*7*(8 - extreme_note[3:0]);  // F; 7 notes per octave, 6 pixels per note  
//         7,8: y_stem = 9 + 6*7*(8 - extreme_note[3:0]);  // G; 7 notes per octave, 6 pixels per note        
//         9,10: y_stem = 6 + 6*7*(8 - extreme_note[3:0]);  // A; 7 notes per octave, 6 pixels per note          
//         11: y_stem = 3 + 6*7*(8 - extreme_note[3:0]);  // B; 7 notes per octave, 6 pixels per note        
//         default: y_stem = 150;
//     endcase
// end



endmodule
`default_nettype wire
