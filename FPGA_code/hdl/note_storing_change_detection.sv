`timescale 1ns / 1ps
`default_nettype none

module note_storing_change_detection(
    input wire rst_in,
    input wire clk_in,
    input logic [4:0] [7:0] y_dot_in,
    input logic [7:0]  y_stem_in,
    input logic [4:0] sharp_shift_in [2:0],
    input logic [4:0] rhythm_shift_in [7:0],
    input logic [4:0] note_width_in [6:0],
    input logic [5:0] current_staff_cell_in,
    input logic [4:0] start_staff_cell_in,
    input logic [4:0] notes_in [7:0],
    input logic [3:0] note_rhythms_in [4:0],
    output logic [11:0] detected_note_out [4:0],
    output logic [4:0] [7:0] y_dot_out,
    output logic [7:0]  y_stem_out,
    output logic [4:0] sharp_shift_out [2:0],
    output logic [4:0] rhythm_shift_out [7:0],
    output logic [4:0] note_width_out [6:0],
    output logic [5:0] current_staff_cell_out,
    output logic [4:0] start_staff_cell_out
);

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            y_dot <= 0;
            y_stem <= 0;
            for(int i = 0; i<5; i = i + 1)begin
                detected_note_out[i] <= 12'h0ff;
                sharp_shift[i] <= 0;
                rhythm_shift[i] <= 0;
                note_width[i] <= 0;
                start_staff_cell[i] <= 0;
            end
            for(int j = 0; j<5; j = j + 1)begin
                current_staff_cell[j] <= 0;
            end
        end else begin
            // buffering signals
            y_dot_out <= y_dot_in;
            y_stem_out <= y_stem_in;
            sharp_shift_out <= sharp_shift_in;
            rhythm_shift_out <= rhythm_shift_in;
            note_width_out <= note_width_in;
            current_staff_cell_out <= current_staff_cell_in;
            start_staff_cell_out <= start_staff_cell_in;


            // actual logic
            if(current_staff_cell_out != current_staff_cell_in)begin
             // keep track of any changes between sixteenth_metronome <= (bpm >> 2) and sixteenth_metronome + (bpm >> 2) >= 1_500_000_000
                for(int i = 0; i<5; i = i + 1)begin
                    detected_note_out[i] <= 12'h0ff;
                end
            end else begin
                for(int i = 0; i<5; i = i + 1)begin
                    if(detected_note_out[i][7:0] != {notes_in[i]})begin
                        detected_note_out[i] <= {note_rhythmss_in[i], notes_in[i]}
                    end else begin
                        detected_note_out[i]
                    end
                end
            end
        end
    end



endmodule
`default_nettype wire
