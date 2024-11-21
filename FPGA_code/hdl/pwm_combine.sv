`timescale 1ns / 1ps
`default_nettype none

module pwm_combine(
            input wire clk_in,
            input wire rst_in,
            input wire midi_burst_ready_in,
            input wire [2:0] on_msg_count_in,
            input wire [31:0] midi_burst_data_in [4:0],
            output logic pwm_ready,
            output logic sig_out);

    // first it will see what notes are coming in
    // then it will cast them to their corresponding note
    // then it will get the correct note from memory
    // then it will get the data for those sine waves and add them
    // then it will send this informaiton into a pwm module to get synthesized
    // TODO: define something to react to the velocity
    // Need to store notes in the following order from 0 to 11:
    // C, C#, D, D#, E, F, F#, G, G#, A, A#, B

    logic [7:0] note_value_array [4:0];
    logic [7:0] note_velocity_array [4:0];
    logic [3:0] octave_count [4:0];
    logic [2:0] msg_count;
    logic [2:0] calc_done_count;
    
    enum logic [2:0] {IDLE,PROCESSING_DATA,RETRIEVING_WAVEFORM,COMBINING_WAVEFORM,TRANSMITTING} combine_state;
        
    always_ff @(posedge clk_in)begin
        if(rst_in)begin
            // reset everything and should be the same thing as the IDLE state
            sig_out <= 0;
            msg_count <= 0;
            calc_done_count <= 0;
            pwm_ready <= 0;
            for(int j = 0; j<5; j = j + 1)begin
                octave_count[j] <= 0;
                note_value_array[j] <= 0;
                note_velocity_array[j] <= 0;
            end
        end else begin
            case(combine_state)
                IDLE: begin
                    sig_out <= 0;
                    calc_done_count <= 0;
                    msg_count <= 0;
                    pwm_ready <= 0;
                    for(int j = 0; j<5; j = j + 1)begin
                        octave_count[j] <= 0;
                        note_value_array[j] <= 0;
                        note_velocity_array[j] <= 0;
                    end
                    if(midi_burst_ready_in)begin
                        // there is valid data, capture it
                        msg_count <= on_msg_count_in;
                        for(int i = 0; i<5;i = i + 1)begin
                            note_value_array[i] <= midi_burst_data_in[i][15:8]; // from the definition in midi burst
                            note_velocity_array[i] <= midi_burst_data_in[i][7:0]; // from the definition in midi_burst
                        end
                        combine_state <= PROCESSING_DATA;
                    end
                    // implicit else remain in IDLE
                end
                PROCESSING_DATA: begin
                    // now that the data has been captured, find the octave and note
                    for(int j = 0; j<5; j = j + 1)begin
                        if(note_value_array[j] > 11)begin
                            note_value_array[j] <= note_value_array[j] - 12;
                            octave_count[j] <= octave_count[j] + 1;
                        end else begin
                            // going to count the number that are under 11 to check if done
                            if(calc_done_count == msg_count) begin
                                combine_state <= RETRIEVING_WAVEFORM;
                            end else begin
                                calc_done_count <= calc_done_count + 1;
                            end         
                        end
                    end
                end
                RETRIEVING_WAVEFORM: begin
                    // now that I have the note and the octave, I can get the proper sines
                    // pseudocode:
                    // some for loop to go through all the note_values and get the proper note
                    
                end
                COMBINING_WAVEFORM: begin
                    // add the number of sine waves that there are notes
                end
                TRANSMITTING: begin
                    pwm_ready <= 1;
                end
                default: combine_state <= IDLE;
            endcase
        end

    end

endmodule

`default_nettype wire