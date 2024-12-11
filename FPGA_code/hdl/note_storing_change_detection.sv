`timescale 1ns / 1ps
`default_nettype none

module note_storing_change_detection(
    input wire rst_in,
    input wire clk_in,
    
    input wire [4:0] [8:0] y_dot_in,
    input wire [8:0]  y_stem_in,
    
    input wire [2:0] sharp_shift_in [4:0],
    input wire [7:0] rhythm_shift_in [4:0],
    input wire [6:0] note_width_in [4:0],
    
    input wire [5:0] current_staff_cell_in,
    
    input wire [7:0] notes_in [4:0],
    input wire [4:0][3:0] note_rhythms_in ,
    
    output logic [11:0] detected_note_out [4:0],
    output logic [4:0] [8:0] y_dot_out,
    output logic [8:0]  y_stem_out,
    output logic [2:0] sharp_shift_out [4:0],
    output logic [7:0] rhythm_shift_out [4:0],
    output logic [6:0] note_width_out [4:0],
    output logic [5:0] current_staff_cell_out
);

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            y_dot_out <= 0;
            y_stem_out <= 0;
            for(int i = 0; i<5; i = i + 1)begin
                detected_note_out[i] <= 12'h0ff;
                sharp_shift_out[i] <= 0;
                rhythm_shift_out[i] <= 0;
                note_width_out[i] <= 0;
            end
            for(int j = 0; j<5; j = j + 1)begin
                current_staff_cell_out[j] <= 0;
            end
        end else begin
            // buffering signals
            y_dot_out <= y_dot_in;
            y_stem_out <= y_stem_in;
            
            for (int i = 0; i < 5; i++) begin
                sharp_shift_out[i] <= sharp_shift_in[i];
                rhythm_shift_out[i] <= rhythm_shift_in[i];
                note_width_out[i] <= note_width_in[i];
            end
            current_staff_cell_out <= current_staff_cell_in;


            // actual logic
            if(current_staff_cell_out != current_staff_cell_in)begin
             // keep track of any changes between sixteenth_metronome <= (bpm >> 2) and sixteenth_metronome + (bpm >> 2) >= 1_500_000_000
                for(int i = 0; i<5; i = i + 1)begin
                    detected_note_out[i] <= 12'h0ff;
                end
            end else begin
                for(int i = 0; i<5; i = i + 1)begin
                    if(detected_note_out[i][7:0] != {notes_in[i]})begin
                        detected_note_out[i] <= {note_rhythms_in[i], notes_in[i]};
                    end
                end
            end
        end
    end
endmodule

`default_nettype wire
