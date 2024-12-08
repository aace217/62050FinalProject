`timescale 1ns / 1ps
`default_nettype none

module note_duration (
    input wire [3:0] octave_count[4:0],
    input wire [3:0] note_value_array[4:0],
    input wire valid_note_in,
    input wire [4:0] note_on_in,
    input wire clk_in,
    input wire rst_in,
    output logic [7:0] notes_out[4:0],
    output logic [31:0] durations_out[4:0]
);

// Prepare yourself for the yapfest...
// anthony i'm so sorry i cannot not do the tertiary statements skull
logic [4:0][15:0] received_note;
assign received_note[4] = {note_value_array[4], octave_count[4]};
assign received_note[3] = {note_value_array[3], octave_count[3]};
assign received_note[2] = {note_value_array[2], octave_count[2]};
assign received_note[1] = {note_value_array[1], octave_count[1]};
assign received_note[0] = {note_value_array[0], octave_count[0]};

logic [7:0] note1, note2, note3, note4, note5;
logic [29:0] duration1, duration2, duration3, duration4, duration5;
// note corresponds with current notes in module, 1,2,3,4,5
logic [2:0] note_changed1, note_changed2, note_changed3, note_changed4, note_changed5;

// note corresponds to incoming notes A,B,C,D,E
logic [2:0] note_changedA, note_changedB, note_changedC, note_changedD, note_changedE;



always_comb begin
    // if the received notes have not changed, note_changedLETTER = 0
    // if the received notes have turned off, note_changedLETTER = 6
    // if the received notes have changed otherwise, note_changedLETTER = unique index

    if (valid_note_in) begin
        // received note A; if A is ON and equals any of the current notes, it is not changed
        note_changedA =   (note_on_in[4] && 
                        (received_note[4][15:8] == note1 || 
                        received_note[4][15:8] == note2 || 
                        received_note[4][15:8] == note3 || 
                        received_note[4][15:8] == note4 || 
                        received_note[4][15:8] == note5
                        ))? 0 : (note_on_in[4] == 0)? 6: 1;
        // received note B; if B is ON and equals any of the current notes, it is not changed
        note_changedB =   (note_on_in[3] && 
                        (received_note[3][15:8] == note1 || 
                        received_note[3][15:8] == note2 || 
                        received_note[3][15:8] == note3 || 
                        received_note[3][15:8] == note4 || 
                        received_note[3][15:8] == note5
                        ))? 0 : (note_on_in[3] == 0)? 6:2;
        // received note C; if C is ON and equals any of the current notes, it is not changed
        note_changedC =   (note_on_in[2] && 
                        (received_note[2][15:8] == note1 || 
                        received_note[2][15:8] == note2 || 
                        received_note[2][15:8] == note3 || 
                        received_note[2][15:8] == note4 || 
                        received_note[2][15:8] == note5
                        ))? 0 : (note_on_in[2] == 0)? 6:3;
        // received note D; if D is ON and equals any of the current notes, it is not changed
        note_changedD =   (note_on_in[1] && 
                        (received_note[1][15:8] == note1 || 
                        received_note[1][15:8] == note2 || 
                        received_note[1][15:8] == note3 || 
                        received_note[1][15:8] == note4 || 
                        received_note[1][15:8] == note5
                        ))? 0 : (note_on_in[1] == 0)? 6:4;
        // received note E; if E is ON and equals any of the current notes, it is not changed
        note_changedE =   (note_on_in[0] && 
                        (received_note[0][15:8] == note1 || 
                        received_note[0][15:8] == note2 || 
                        received_note[0][15:8] == note3 || 
                        received_note[0][15:8] == note4 || 
                        received_note[0][15:8] == note5
                        ))? 0 : (note_on_in[0] == 0)? 6:5;
        // -------------------------------------------------------
        // the point is to match a changed received note to a changed internal note register by matching their index
        // index = 6 if the note just turned off, the unique index otherwise. 0 if stored register's note doesn't change

        // if current note 1 equals any of the incoming notes, the note has not changed
        note_changed1 = (note1 == received_note[4][15:8] && note_on_in[4] ||
            note1 == received_note[3][15:8] && note_on_in[3] ||
            note1 == received_note[2][15:8] && note_on_in[2] ||
            note1 == received_note[1][15:8] && note_on_in[1] ||
            note1 == received_note[0][15:8] && note_on_in[0] 
        )? 0 : // match it to the first free note_changedLETTER
        (note_changedA)? note_changedA:
        (note_changedB)? note_changedB:
        (note_changedC)? note_changedC:
        (note_changedD)? note_changedD:
        (note_changedE)? note_changedE: 6; 

        // if current note 2 equals any of the incoming notes, the note has not changed
        note_changed2 = (note2 == received_note[4][15:8] && note_on_in[4] ||
            note2 == received_note[3][15:8] && note_on_in[3] ||
            note2 == received_note[2][15:8] && note_on_in[2] ||
            note2 == received_note[1][15:8] && note_on_in[1] ||
            note2 == received_note[0][15:8] && note_on_in[0] 
        )? 0 : // match it to the first free note_changedLETTER
        (note_changedA && note_changed1 != 1)? note_changedA:
        (note_changedB && note_changed1 != 2)? note_changedB:
        (note_changedC && note_changed1 != 3)? note_changedC:
        (note_changedD && note_changed1 != 4)? note_changedD:
        (note_changedE && note_changed1 != 5)? note_changedE:6;   

        // if current note 3 equals any of the incoming notes, the note has not changed
        note_changed3 = (note3 == received_note[4][15:8] && note_on_in[4] ||
            note3 == received_note[3][15:8] && note_on_in[3] ||
            note3 == received_note[2][15:8] && note_on_in[2] ||
            note3 == received_note[1][15:8] && note_on_in[1] ||
            note3 == received_note[0][15:8] && note_on_in[0] 
        )? 0 : // match it to the first free note_changedLETTER
        (note_changedA && note_changed1 != 1 && note_changed2 != 1)? note_changedA:
        (note_changedB && note_changed1 != 2 && note_changed2 != 2)? note_changedB:
        (note_changedC && note_changed1 != 3 && note_changed2 != 3)? note_changedC:
        (note_changedD && note_changed1 != 4 && note_changed2 != 4)? note_changedD:
        (note_changedE && note_changed1 != 5 && note_changed2 != 5)? note_changedE:6;

        // if current note 4 equals any of the incoming notes, the note has not changed
        note_changed4 = (note4 == received_note[4][15:8] && note_on_in[4] ||
            note4 == received_note[3][15:8] && note_on_in[3] ||
            note4 == received_note[2][15:8] && note_on_in[2] ||
            note4 == received_note[1][15:8] && note_on_in[1] ||
            note4 == received_note[0][15:8] && note_on_in[0] 
        )? 0 : // match it to the first free note_changedLETTER
        (note_changedA && note_changed1 != 1 && note_changed2 != 1 && note_changed3 != 1)? note_changedA:
        (note_changedB && note_changed1 != 2 && note_changed2 != 2 && note_changed3 != 2)? note_changedB:
        (note_changedC && note_changed1 != 3 && note_changed2 != 3 && note_changed3 != 3)? note_changedC:
        (note_changedD && note_changed1 != 4 && note_changed2 != 4 && note_changed3 != 4)? note_changedD:
        (note_changedE && note_changed1 != 5 && note_changed2 != 5 && note_changed3 != 5)? note_changedE:6; 

        // if current note 5 equals any of the incoming notes, the note has not changed
        note_changed5 = (note5 == received_note[4][15:8] && note_on_in[4] ||
            note5 == received_note[3][15:8] && note_on_in[3] ||
            note5 == received_note[2][15:8] && note_on_in[2] ||
            note5 == received_note[1][15:8] && note_on_in[1] ||
            note5 == received_note[0][15:8] && note_on_in[0] 
        )? 0 : // match it to the first free note_changedLETTER
        (note_changedA && note_changed1 != 1 && note_changed2 != 1 && note_changed3 != 1 && note_changed4 != 1)? note_changedA:
        (note_changedB && note_changed1 != 2 && note_changed2 != 2 && note_changed3 != 2 && note_changed4 != 2)? note_changedB:
        (note_changedC && note_changed1 != 3 && note_changed2 != 3 && note_changed3 != 3 && note_changed4 != 3)? note_changedC:
        (note_changedD && note_changed1 != 4 && note_changed2 != 4 && note_changed3 != 4 && note_changed4 != 4)? note_changedD:
        (note_changedE && note_changed1 != 5 && note_changed2 != 5 && note_changed3 != 5 && note_changed4 != 5)? note_changedE:6; 
    end else begin
        note_changedA = 0;
        note_changedB = 0;
        note_changedC = 0;
        note_changedD = 0;
        note_changedE = 0;
        note_changed1 = 0;
        note_changed2 = 0;
        note_changed3 = 0;
        note_changed4 = 0;
        note_changed5 = 0;
    end

    notes_out[4] = note1;
    notes_out[3] = note2;
    notes_out[2] = note3;
    notes_out[1] = note4;
    notes_out[0] = note5;
    durations_out[4] = duration1;
    durations_out[3] = duration2;
    durations_out[2] = duration3;
    durations_out[1] = duration4;
    durations_out[0] = duration5;
end

always_ff @(posedge clk_in) begin
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
        // max duration: 40 beats/minute (min bpm?) * minute/60 sec * 1 sec/200e6 cycles = idk beats/cycles or 300,000,000 = cycles/beat (on the quarter note)
        // 4 quarter notes possible total (beats) per measure * 300,000,000 cycles/beats = 1,200,000,000 cycles is max duration, about 30 bits
        // if at max, stay at max forever
        duration1 <= (note_changed1 != 0 || duration1 == 159_999_999)? 0 : duration1 + 1;
        duration2 <= (note_changed2 != 0 || duration2 == 159_999_999)? 0 : duration2 + 1;
        duration3 <= (note_changed3 != 0 || duration3 == 159_999_999)? 0 : duration3 + 1;
        duration4 <= (note_changed4 != 0 || duration4 == 159_999_999)? 0 : duration4 + 1;
        duration5 <= (note_changed5 != 0 || duration5 == 159_999_999)? 0 : duration5 + 1;

        note1 <=    (note_changed1 == 0)? note1: 
                    (note_changed1 == 6)? 0: 
                    (note_changed1 == note_changedA)? received_note[4][15:8]:
                    (note_changed1 == note_changedB)? received_note[3][15:8]:
                    (note_changed1 == note_changedC)? received_note[2][15:8]:
                    (note_changed1 == note_changedD)? received_note[1][15:8]:
                    (note_changed1 == note_changedE)? received_note[0][15:8]: 0;
        note2 <=    (note_changed2 == 0)? note2: 
                    (note_changed2 == 6)? 0: 
                    (note_changed2 == note_changedA)? received_note[4][15:8]:
                    (note_changed2 == note_changedB)? received_note[3][15:8]:
                    (note_changed2 == note_changedC)? received_note[2][15:8]:
                    (note_changed2 == note_changedD)? received_note[1][15:8]:
                    (note_changed2 == note_changedE)? received_note[0][15:8]: 0;
        note3 <=    (note_changed3 == 0)? note3: 
                    (note_changed3 == 6)? 0: 
                    (note_changed3 == note_changedA)? received_note[4][15:8]:
                    (note_changed3 == note_changedB)? received_note[3][15:8]:
                    (note_changed3 == note_changedC)? received_note[2][15:8]:
                    (note_changed3 == note_changedD)? received_note[1][15:8]:
                    (note_changed3 == note_changedE)? received_note[0][15:8]: 0;
        note4 <=    (note_changed4 == 0)? note4: 
                    (note_changed4 == 6)? 0: 
                    (note_changed4 == note_changedA)? received_note[4][15:8]:
                    (note_changed4 == note_changedB)? received_note[3][15:8]:
                    (note_changed4 == note_changedC)? received_note[2][15:8]:
                    (note_changed4 == note_changedD)? received_note[1][15:8]:
                    (note_changed4 == note_changedE)? received_note[0][15:8]: 0;
        note5 <=    (note_changed5 == 0)? note5: 
                    (note_changed5 == 6)? 0:    
                    (note_changed5 == note_changedA)? received_note[4][15:8]:
                    (note_changed5 == note_changedB)? received_note[3][15:8]:
                    (note_changed5 == note_changedC)? received_note[2][15:8]:
                    (note_changed5 == note_changedD)? received_note[1][15:8]:
                    (note_changed5 == note_changedE)? received_note[0][15:8]: 0;
    end
end

endmodule

`default_nettype wire
