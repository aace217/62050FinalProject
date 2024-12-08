`timescale 1ns / 1ps
`default_nettype none

module note_duration_run_it_back (
    input wire [3:0] octave_count[4:0],
    input wire [3:0] note_value_array[4:0],
    input wire valid_note_in,
    input wire [4:0] note_on_in,
    input wire [7:0] bpm,
    input wire clk_in,
    input wire rst_in,
    output logic [7:0] notes_out[4:0],
    output logic [29:0] durations_out[4:0]
);

logic [3:0] prev_notes [4:0];
logic [3:0] prev_octave [4:0];
logic [4:0] prev_note_on;

always_ff @(posedge clk_in) begin
    if (rst_in) begin
        for (int i = 0; i < 5; i ++) begin
            notes_out[i] <= 0;
            durations_out[i] <= 0;
            prev_notes[i] <= 0;
            prev_octave[i] <= 0;
            prev_note_on[i] <= 0;
        end
    end else begin
        if (valid_note_in) begin
            for (int i = 0; i < 5; i ++) begin
                prev_notes[i] <= note_value_array[i];
                prev_octave[i] <= octave_count[i];
                prev_note_on[i] <= note_on_in[i];
                durations_out[i] <= (prev_octave[i] != octave_count[i] || 
                                    prev_notes[i] != note_value_array[i] ||
                                    prev_note_on[i] != note_on_in[i] ||
                                    durations_out[i] * (bpm >> 2) >= 64'd23_999_999_999)? 0 : durations_out[i] + 1;
                notes_out[i] <= (note_on_in[i])? {note_value_array[i], octave_count[i]}: 8'hFF;
                // 15 is not a valid note pitch, 15 is also not a valid octave...
                // thus, if note is NOT ON, then the note is represented by all 1's
            end
        end 
    end
end

endmodule

`default_nettype wire