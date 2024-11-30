`timescale 1ns / 1ps
`default_nettype none

module staff_creation (
    input wire [10:0] hcount,
    input wire [9:0] vcount, 
    input wire [7:0] bpm,
    input wire [159:0] received_note,
    input wire clk_camera_in,
    input wire rst_in,
    input wire [2:0] num_lines,
    output logic [1:0] staff_out,
    output logic staff_valid
);

// Prepare yourself for the yapfest...
// anthony i'm so sorry i cannot not do the tertiary statements skull

// _____________________________________
// ACCEPTING DATA FROM RECEIVED DATA

// note corresponds with current notes in module, 1,2,3,4,5
logic [7:0] note1, note2, note3, note4, note5;
logic [29:0] duration1, duration2, duration3, duration4, duration5;
logic [2:0] note_changed1, note_changed2, note_changed3, note_changed4, note_changed5;

// note corresponds to incoming notes A,B,C,D,E
logic [2:0] note_changedA, note_changedB, note_changedC, note_changedD, note_changedE;

// received note A: [159:152] = valid, [151:144] = channel, [143: 136] = note, [135: 128] = velocity
// received note B: [127:120] = valid, [119:112] = channel, [111: 104] = note, [103: 96] = velocity
// received note C: [95:88] = valid, [87:80] = channel, [79: 72] = note, [71: 64] = velocity
// received note D: [63:56] = valid, [55:48] = channel, [47: 40] = note, [39: 32] = velocity
// received note E: [31:24] = valid, [23:16] = channel, [15: 8] = note, [7: 0] = velocity

// the only thing that is needed for display is note lowkey, so only keeping the third byte of data

always_comb begin
    // received note A; if A is ON and equals any of the current notes, it is not changed
    note_changedA =   (received_note[159:152] &&          
                    (received_note[143:136] == note1 || 
                    received_note[143:136] == note2 || 
                    received_note[143:136] == note3 || 
                    received_note[143:136] == note4 || 
                    received_note[143:136] == note5
                    ))? 0 : 1;
    // received note B; if B is ON and equals any of the current notes, it is not changed
    note_changedB =   (received_note[127:120] &&          
                    (received_note[111:104] == note1 || 
                    received_note[111:104] == note2 || 
                    received_note[111:104] == note3 || 
                    received_note[111:104] == note4 || 
                    received_note[111:104] == note5
                    ))? 0 : 2;
    // received note C; if C is ON and equals any of the current notes, it is not changed
    note_changedC =   (received_note[95:88] &&          
                    (received_note[79:72] == note1 || 
                    received_note[79:72] == note2 || 
                    received_note[79:72] == note3 || 
                    received_note[79:72] == note4 || 
                    received_note[79:72] == note5
                    ))? 0 : 3;
    // received note D; if D is ON and equals any of the current notes, it is not changed
    note_changedD =   (received_note[63:56] &&          
                    (received_note[47:40] == note1 || 
                    received_note[47:40] == note2 || 
                    received_note[47:40] == note3 || 
                    received_note[47:40] == note4 || 
                    received_note[47:40] == note5
                    ))? 0 : 4;
    // received note E; if E is ON and equals any of the current notes, it is not changed
    note_changedE =   (received_note[31:24] &&          
                    (received_note[15:8] == note1 || 
                    received_note[15:8] == note2 || 
                    received_note[15:8] == note3 || 
                    received_note[15:8] == note4 || 
                    received_note[15:8] == note5
                    ))? 0 : 5;
// -------------------------------------------------------
    // if current note 1 equals any of the incoming notes, the note has not changed
    note_changed1 = (note1 == received_note[143:136] && received_note[159:152] ||
        note1 == received_note[111:104] && received_note[127:120] ||
        note1 == received_note[79:72] && received_note[95:88] ||
        note1 == received_note[47:40] && received_note[63:56] ||
        note1 == received_note[15:8] && received_note[31:24] 
    )? 0 : // match it to the first free note_changedLETTER
    (note_changedA)? 1:
    (note_changedB)? 2:
    (note_changedC)? 3:
    (note_changedD)? 4:
    (note_changedE)? 5: 6;    
    // if current note 2 equals any of the incoming notes, the note has not changed
    note_changed2 = (note2 == received_note[143:136] && received_note[159:152] ||
        note2 == received_note[111:104] && received_note[127:120] ||
        note2 == received_note[79:72] && received_note[95:88] ||
        note2 == received_note[47:40] && received_note[63:56] ||
        note2 == received_note[15:8] && received_note[31:24]
    )? 0 : // match it to the first free note_changedLETTER
    (note_changedA && note_changed1 != 1)? 1:
    (note_changedB && note_changed1 != 2)? 2:
    (note_changedC && note_changed1 != 3)? 3:
    (note_changedD && note_changed1 != 4)? 4:
    (note_changedE && note_changed1 != 5)? 5:6;   
    // if current note 3 equals any of the incoming notes, the note has not changed
    note_changed3 = (note3 == received_note[143:136] && received_note[159:152] ||
        note3 == received_note[111:104] && received_note[127:120] ||
        note3 == received_note[79:72] && received_note[95:88] ||
        note3 == received_note[47:40] && received_note[63:56] ||
        note3 == received_note[15:8] && received_note[31:24]
    )? 0 : // match it to the first free note_changedLETTER
    (note_changedA && note_changed1 != 1 && note_changed2 != 1)? 1:
    (note_changedB && note_changed1 != 2 && note_changed2 != 2)? 2:
    (note_changedC && note_changed1 != 3 && note_changed2 != 3)? 3:
    (note_changedD && note_changed1 != 4 && note_changed2 != 4)? 4:
    (note_changedE && note_changed1 != 5 && note_changed2 != 5)? 5:6; 
    // if current note 4 equals any of the incoming notes, the note has not changed
    note_changed4 = (note4 == received_note[143:136] && received_note[159:152] ||
        note4 == received_note[111:104] && received_note[127:120] ||
        note4 == received_note[79:72] && received_note[95:88] ||
        note4 == received_note[47:40] && received_note[63:56] ||
        note4 == received_note[15:8] && received_note[31:24]
    )? 0 : // match it to the first free note_changedLETTER
    (note_changedA && note_changed1 != 1 && note_changed2 != 1 && note_changed3 != 1)? 1:
    (note_changedB && note_changed1 != 2 && note_changed2 != 2 && note_changed3 != 2)? 2:
    (note_changedC && note_changed1 != 3 && note_changed2 != 3 && note_changed3 != 3)? 3:
    (note_changedD && note_changed1 != 4 && note_changed2 != 4 && note_changed3 != 4)? 4:
    (note_changedE && note_changed1 != 5 && note_changed2 != 5 && note_changed3 != 5)? 5:6; 
    // if current note 5 equals any of the incoming notes, the note has not changed
    note_changed5 = (note5 == received_note[143:136] && received_note[159:152] ||
        note5 == received_note[111:104] && received_note[127:120] ||
        note5 == received_note[79:72] && received_note[95:88] ||
        note5 == received_note[47:40] && received_note[63:56] ||
        note5 == received_note[15:8] && received_note[31:24]
    )? 0 : // match it to the first free note_changedLETTER
    (note_changedA && note_changed1 != 1 && note_changed2 != 1 && note_changed3 != 1 && note_changed4 != 1)? 1:
    (note_changedB && note_changed1 != 2 && note_changed2 != 2 && note_changed3 != 2 && note_changed4 != 2)? 2:
    (note_changedC && note_changed1 != 3 && note_changed2 != 3 && note_changed3 != 3 && note_changed4 != 3)? 3:
    (note_changedD && note_changed1 != 4 && note_changed2 != 4 && note_changed3 != 4 && note_changed4 != 4)? 4:
    (note_changedE && note_changed1 != 5 && note_changed2 != 5 && note_changed3 != 5 && note_changed4 != 5)? 5:6; 
end

always_ff @(posedge clk_camera_in) begin
    if (rst_in) begin
        note1 <= 0;
        note2 <= 0;
        note3 <= 0;
        note4 <= 0;
        note5 <= 0;
        duration1 <= 0;
        duration2 <= 0;
        duration3 <= 0;
        duration4 <= 0;
        duration5 <= 0;
        note_changed1 <= 0;
        note_changed2 <= 0;
        note_changed3 <= 0;
        note_changed4 <= 0;
        note_changed5 <= 0;
        note_changedA <= 0;
        note_changedB <= 0;
        note_changedC <= 0;
        note_changedD <= 0;
        note_changedE <= 0;
    end else begin
        // get duration of inputted note in units of cycles
        // max duration: 300 beats/minute (max bpm?) * minute/60 sec * 1 sec/200e6 cycles = 2.5 * 10^-8 beats/cycles or 40,000,000 = cycles/beat (on the quarter note)
        // 16 quarter notes possible total (beats) * 40,000,000 cycles/beats = 640,000,000 cycles is max duration, about 30 bits
        // if at max, stay at max forever
        duration1 <= (note_changed1 != 0)? 0 : (duration1 == 39_999_999)? 39_999_999: duration1 + 1;
        duration2 <= (note_changed2 != 0)? 0 : (duration2 == 39_999_999)? 39_999_999: duration2 + 1;
        duration3 <= (note_changed3 != 0)? 0 : (duration3 == 39_999_999)? 39_999_999: duration3 + 1;
        duration4 <= (note_changed4 != 0)? 0 : (duration4 == 39_999_999)? 39_999_999: duration4 + 1;
        duration5 <= (note_changed5 != 0)? 0 : (duration5 == 39_999_999)? 39_999_999: duration5 + 1;

        note1 <=    (note_changed1 == 0)? note1: 
                    (note_changed1 == note_changedA)? received_note[143:136]:
                    (note_changed1 == note_changedB)? received_note[111:104]:
                    (note_changed1 == note_changedC)? received_note[79:72]:
                    (note_changed1 == note_changedD)? received_note[47:40]:
                    received_note[15:8];
        note2 <=    (note_changed2 == 0)? note2: 
                    (note_changed2 == note_changedA)? received_note[143:136]:
                    (note_changed2 == note_changedB)? received_note[111:104]:
                    (note_changed2 == note_changedC)? received_note[79:72]:
                    (note_changed2 == note_changedD)? received_note[47:40]:
                    received_note[15:8];
        note3 <=    (note_changed3 == 0)? note3: 
                    (note_changed3 == note_changedA)? received_note[143:136]:
                    (note_changed3 == note_changedB)? received_note[111:104]:
                    (note_changed3 == note_changedC)? received_note[79:72]:
                    (note_changed3 == note_changedD)? received_note[47:40]:
                    received_note[15:8];
        note4 <=    (note_changed4 == 0)? note4: 
                    (note_changed4 == note_changedA)? received_note[143:136]:
                    (note_changed4 == note_changedB)? received_note[111:104]:
                    (note_changed4 == note_changedC)? received_note[79:72]:
                    (note_changed4 == note_changedD)? received_note[47:40]:
                    received_note[15:8];
        note5 <=    (note_changed5 == 0)? note5: 
                    (note_changed5 == note_changedA)? received_note[143:136]:
                    (note_changed5 == note_changedB)? received_note[111:104]:
                    (note_changed5 == note_changedC)? received_note[79:72]:
                    (note_changed5 == note_changedD)? received_note[47:40]:
                    received_note[15:8];
    end
end

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
