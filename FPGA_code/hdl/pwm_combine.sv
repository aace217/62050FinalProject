`timescale 1ns / 1ps
`default_nettype none

module pwm_combine(
            input wire clk_in,
            input wire rst_in,
            input wire midi_burst_ready_in,
            input wire [2:0] on_msg_count_in,
            input wire [20:0] midi_burst_data_in [4:0],
            input wire only_off_msgs,
            output logic vals_ready,
            output logic [3:0] octave_count [4:0],
            output logic [7:0] note_value_array [4:0],
            output logic [7:0] note_velocity_array [4:0]
            );

    // first it will see what notes are coming in
    // then it will cast them to their corresponding note
    // then it will get the correct note from memory
    // then it will get the data for those sine waves and add them
    // then it will send this informaiton into a pwm module to get synthesized
    // TODO: define something to react to the velocity
    // Need to store notes in the following order from 0 to 11:
    // C, C#, D, D#, E, F, F#, G, G#, A, A#, B

    logic [2:0] msg_count;
    logic [3:0] intermed_oct;
    logic [3:0] intermed_note;
    logic all_notes_processed,start_mod,mod_done;

    
    enum logic [2:0] {IDLE,PROCESSING_DATA,RETRIEVING_WAVEFORM,COMBINING_WAVEFORM,TRANSMITTING} combine_state;

    mod12 modulo1 (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .good_data_in(midi_burst_ready_in),
        .note_number_in(midi_burst_data_in[0][15:8]),
        .val_out(intermed_note),
        .subtractions_out(intermed_oct),
        .done(mod_done)
    );

    
    always_ff @(posedge clk_in)begin
        if(rst_in)begin
            // reset everything and should be the same thing as the IDLE state
            //sig_out <= 0;
            msg_count <= 0;
            //calc_done_count <= 0;
            vals_ready <= 0;
            for(int n = 0; n<5; n = n + 1)begin
                octave_count[n] <= 0;
                note_value_array[n] <= 0;
                note_velocity_array[n] <= 0;
            end
        end else begin
            case(combine_state)
                IDLE: begin
                    //sig_out <= 0;
                    vals_ready <= 0;
                    msg_count <= 0;
                    if(midi_burst_ready_in)begin
                        // there is valid data, capture it
                        msg_count <= on_msg_count_in;
                        for(int i = 0; i<5;i = i + 1)begin
                            note_velocity_array[i] <= midi_burst_data_in[i][7:0]; // from the definition in midi_burst
                        end
                        combine_state <= PROCESSING_DATA;
                    end else begin
                        for(int j = 0; j<5; j = j + 1)begin
                            octave_count[j] <= 0;
                            note_value_array[j] <= 0;
                            note_velocity_array[j] <= 0;
                        end
                    end
                    // implicit else remain in IDLE
                end
                PROCESSING_DATA: begin
                    // now that the data has been captured, find the octave and note
                    // mod12 will never be done in one cycle
                    if(mod_done)begin
                        combine_state <= RETRIEVING_WAVEFORM;
                        note_value_array[0] <= intermed_note;
                        octave_count[0] <= intermed_oct;
                    end

                end
                RETRIEVING_WAVEFORM: begin
                    // now that I have the note and the octave, I can get the proper sines
                    // pseudocode:
                    // some for loop to go through all the note_values and get the proper note
                    combine_state <= IDLE;
                    vals_ready <= 1;
                    
                    //combine_state <= COMBINING_WAVEFORM;
                end
                COMBINING_WAVEFORM: begin
                    // add the number of sine waves that there are notes
                    combine_state <= TRANSMITTING;
                end
                TRANSMITTING: begin
                    //pwm_ready <= 1;
                    combine_state <= IDLE;
                end
                default: combine_state <= IDLE;
            endcase
        end

    end

endmodule

`default_nettype wire