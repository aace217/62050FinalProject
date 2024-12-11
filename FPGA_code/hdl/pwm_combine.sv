`timescale 1ns / 1ps
`default_nettype none

module pwm_combine(
            input wire clk_in,
            input wire rst_in,
            input wire midi_burst_change_in,
            input wire [4:0] on_array_in,
            input wire [15:0] midi_burst_data_in [4:0],
            output logic [3:0] octave_count [4:0],
            output logic [3:0] note_value_array [4:0],
            output logic [7:0] note_velocity_array [4:0],
            output logic midi_data_parsed_ready_out,
            output logic pwm_data_ready_out,
            output logic [7:0] pwm_data_out,
            output logic [2:0] state_out,
            output logic [2:0] msg_count,
            output logic [2:0] mods_done,
            output logic [4:0] on_array_out
            );

    // first it will see what notes are coming in
    // then it will cast them to their corresponding note
    // then it will get the correct note from memory
    // then it will get the data for those sine waves and add them
    // then it will send this informaiton into a pwm module to get synthesized
    // TODO: define something to react to the velocity
    // Need to store notes in the following order from 0 to 11:
    // C, C#, D, D#, E, F, F#, G, G#, A, A#, B
    parameter SAMPLE_RATE = 2268*2;
    //logic [2:0] msg_count;
    logic [3:0] intermed_oct[4:0];
    logic [3:0] oct_buf [4:0];
    logic [3:0] note_buf [4:0];
    logic [3:0] intermed_note [4:0];
    logic [7:0] sine_data [4:0];
    logic [7:0] sine_buf [4:0];
    logic signed [20:0] coef_array_buf [4:0];
    logic [20:0] coef_array [4:0];
    logic [17:0] cycle_wait_array [4:0];
    logic [17:0] smallest_cycle_wait;
    logic [2:0] smallest_cycle_wait_index,smallest_cycle_wait_index_buf;
    logic signed [15:0] sum,shifted_sum;
    logic [4:0] start_sines;
    logic [$clog2(SAMPLE_RATE)-1:0] sample_rate_count;
    //logic [2:0] mods_done;
    logic [4:0] mod_done;
    logic [3:0] calc_count;
    logic [4:0] valid_buf;
    logic [2:0] done_buf;
    logic [2:0] intermed_msg_count;
    logic [4:0] sine_generated;
    logic [7:0] reset_val;
    logic [7:0] note_velocity_internal_buffer [4:0];
    logic good_data;
    logic rst_mod,rst_sin;
    logic [20:0] coef1,coef2,coef3,coef4;
    logic [20:0] coef1buf,coef2buf,coef3buf,coef4buf;

    always_comb begin
        done_buf = ((valid_buf[4])?mod_done[4]:0) + ((valid_buf[3])?mod_done[3]:0) + ((valid_buf[2])?mod_done[2]:0) + ((valid_buf[1])?mod_done[1]:0);
        intermed_msg_count = on_array_in[4] + on_array_in[3] + on_array_in[2] + on_array_in[1];
        //sum = ((valid_buf[4])?($signed({1'b0,sine_data[4]})-128):0) + ((valid_buf[3])?($signed({1'b0,sine_data[3]})-128):0) + ((valid_buf[2])?($signed({1'b0,sine_data[2]})-128):0) + ((valid_buf[1])?($signed({1'b0,sine_data[1]})-128):0) + ((valid_buf[0])?($signed({1'b0,sine_data[0]})-128):0) + 128;
        //sum = ((valid_buf[4])?($signed({1'b0,sine_data[4]})-128):0) + ((valid_buf[3])?($signed({1'b0,sine_data[3]>>2})-32):0) + ((valid_buf[2])?($signed({1'b0,sine_data[2]}>>2)-32):0) + ((valid_buf[1])?($signed({1'b0,sine_data[1]}>>2)-32):0) + 128;
        sum = ((valid_buf[4])?($signed({1'b0,coef_array[4][7:0]})-128):0) + ((valid_buf[3])?($signed({1'b0,coef_array[3][7:0]})-128):0) + ((valid_buf[2])?($signed({1'b0,coef_array[2][7:0]})-128):0) + ((valid_buf[1])?($signed({1'b0,coef_array[1][7:0]})-128):0) + 128;
        shifted_sum = sum>>>2;
        coef1 = coef_array[1];
        coef2 = coef_array[2];
        coef3 = coef_array[3];
        coef4 = coef_array[4];
        coef1buf = coef_array_buf[1];
        coef2buf = coef_array_buf[2];
        coef3buf = coef_array_buf[3];
        coef4buf = coef_array_buf[4];
    end
    // changes to incorporate more notes:
    // 1.) Shift the sum of 2 waves by two to ensure that it is not bad data
    // 2.) Continuously read the sine waves at the same time so good data is being added

    enum logic [2:0] {IDLE,PROCESSING_DATA,RETRIEVING_WAVEFORM,COMBINING_WAVEFORM,TRANSMITTING} combine_state;


    always_ff @(posedge clk_in)begin
        if(rst_in)begin
            // reset everything and should be the same thing as the IDLE state
            msg_count <= 0;
            pwm_data_ready_out <= 0;
            midi_data_parsed_ready_out <= 0;
            pwm_data_out <= reset_val;
            good_data <= 0;
            valid_buf <= 0;
            smallest_cycle_wait_index_buf <= 0;
            sample_rate_count <= 0;
            calc_count <= 0;
            on_array_out <= 0;
            combine_state <= IDLE;
            for(int n = 0; n<5; n = n + 1)begin
                octave_count[n] <= 0;
                note_value_array[n] <= 0;
                note_velocity_array[n] <= 0;
                oct_buf[n] <= 0;
                note_buf[n] <= 0;
                sine_buf[n] <= 0;
                start_sines[n] <= 0;
                coef_array_buf[n] <= 0;
                coef_array[n] <= 0;
            end
        end else begin
            case(combine_state)
                IDLE: begin
                    //msg_count <= intermed_msg_count;
                    pwm_data_ready_out <= 0;
                    //pwm_data_out <= reset_val;
                    mods_done <= 0;
                    //on_array_out <= 0;
                    sample_rate_count <= 0;
                    smallest_cycle_wait_index_buf <= 0;
                    calc_count <= 0;
                    //good_data <= 0;
                    if(midi_burst_change_in && intermed_msg_count != 0)begin
                        // there is valid data, capture it
                        msg_count <= intermed_msg_count;
                        valid_buf <= on_array_in;
                        for(int j = 1; j<5; j = j + 1)begin
                            note_velocity_array[j] <= midi_burst_data_in[j][7:0];
                        end
                        combine_state <= PROCESSING_DATA;
                    end else begin
                        rst_sin <= 0;
                        rst_mod <= 0;
                        for(int j = 0; j<5; j = j + 1)begin
                            octave_count[j] <= 0;
                            note_value_array[j] <= 0;
                            note_velocity_array[j] <= 0;
                            sine_buf[j] <= 0;
                            oct_buf[j] <= 0;
                            note_buf[j] <= 0;
                            start_sines[j] <= 0;
                            coef_array_buf[j] <= 0;
                            coef_array[j] <= 0;
                        end
                    end
                    // implicit else remain in IDLE
                end
                PROCESSING_DATA: begin
                    // now that the data has been captured, find the octave and note
                    // mod12 will never be done in one cycle
                    if(mods_done == msg_count && msg_count != 0)begin
                        for(int i = 0; i<5; i = i + 1)begin
                            if(valid_buf[i])begin
                                note_value_array[i] <= note_buf[i];
                                octave_count[i] <= oct_buf[i];
                                start_sines[i] <= 1;
                            end
                        end
                        on_array_out <= valid_buf;
                        midi_data_parsed_ready_out <= 1;
                        combine_state <= COMBINING_WAVEFORM;
                    end else begin
                        mods_done <= mods_done + done_buf;
                        for(int j = 0; j<5; j = j + 1)begin
                            if(valid_buf[j] && mod_done[j])begin
                                oct_buf[j] <= intermed_oct[j];
                                note_buf[j] <= intermed_note[j];
                            end
                        end
                    end

                end
                RETRIEVING_WAVEFORM: begin
                    // now that I have the note and the octave, I can get the proper sines
                    // some for loop to go through all the note_values and get the proper note

                    combine_state <= COMBINING_WAVEFORM;
                end
                COMBINING_WAVEFORM: begin
                    // add the number of sine waves that there are notes
                    start_sines <= 0;
                    calc_count <= 0;
                    midi_data_parsed_ready_out <= 0;
                    if(midi_burst_change_in)begin
                        if(intermed_msg_count == 0)begin
                            // go back to idle if it is an empty message
                            combine_state <= IDLE;
                            on_array_out <= 0;
                        end else begin
                            combine_state <= PROCESSING_DATA;
                            calc_count <= 0;
                            mods_done <= 0;
                            valid_buf <= on_array_in;
                            msg_count <= intermed_msg_count;
                            //pwm_data_out <= reset_val;
                            pwm_data_ready_out <= 0;
                            sample_rate_count <= 0;
                            smallest_cycle_wait_index_buf <= 0;
                            //good_data <= 0;
                            for(int j = 0; j<5; j = j + 1)begin
                                note_velocity_array[j] <= midi_burst_data_in[j][7:0];
                                note_value_array[j] <= 0;
                                octave_count[j] <= 0;
                                oct_buf[j] <= 0;
                                note_buf[j] <= 0;
                                sine_buf[j] <= 0;
                                start_sines[j] <= 0;
                                coef_array_buf[j] <= 0;
                                coef_array[j] <= 0;
                            end
                        end
                    end else begin
                        
                        //if(sine_generated[4] || sine_generated[3] || sine_generated[2] || sine_generated[1])begin
                       // if(sine_generated[smallest_cycle_wait_index])begin
                        if(calc_count == 2)begin
                            if(sample_rate_count == SAMPLE_RATE)begin
                                // send data
                                pwm_data_ready_out <= 1;
                                sample_rate_count <= 0;
                                if($signed(shifted_sum) > 255)begin
                                    pwm_data_out <= 255;
                                end else if(shifted_sum < 0)begin
                                    pwm_data_out <= 0;
                                end else begin
                                    // maybe it is going into this case
                                    pwm_data_out <= shifted_sum;
                                end
                                //calc_count <= 0;
                            end else begin
                                sample_rate_count <= sample_rate_count+1;
                            end
                        end else begin
                            for(int i = 0; i<5; i = i +1)begin
                                coef_array_buf[i] <= $signed(note_velocity_array[i]) * ($signed({1'b0,sine_data[i]})-128);
                                //coef_array[i] <= ((coef_array_buf[i]+128*note_velocity_array[i]) >>> 7);
                                coef_array[i] <= (coef_array_buf[i]>>>7)+128;
                            end
                            calc_count <= calc_count + 1;
                        end
                    end
                end
                TRANSMITTING: begin
                    combine_state <= IDLE;
                end
                default: combine_state <= IDLE;
            endcase
        end

    end
    // mod section
    // the mod modules hold their output after pulling done high until they are triggered again
    mod12 modulo0 (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .good_data_in(midi_burst_change_in),
        .note_number_in(midi_burst_data_in[0][15:8]),
        .val_out(intermed_note[0]),
        .subtractions_out(intermed_oct[0]),
        .done(mod_done[0])
    );

    mod12 modulo1 (
       .clk_in(clk_in),
       .rst_in(rst_in),
       .good_data_in(midi_burst_change_in),
       .note_number_in(midi_burst_data_in[1][15:8]),
       .val_out(intermed_note[1]),
       .subtractions_out(intermed_oct[1]),
       .done(mod_done[1])
    );

    mod12 modulo2 (
       .clk_in(clk_in),
       .rst_in(rst_in),
       .good_data_in(midi_burst_change_in),
       .note_number_in(midi_burst_data_in[2][15:8]),
       .val_out(intermed_note[2]),
       .subtractions_out(intermed_oct[2]),
       .done(mod_done[2])
    );

    mod12 modulo3 (
       .clk_in(clk_in),
       .rst_in(rst_mod || rst_in),
       .good_data_in(midi_burst_change_in),
       .note_number_in(midi_burst_data_in[3][15:8]),
       .val_out(intermed_note[3]),
       .subtractions_out(intermed_oct[3]),
       .done(mod_done[3])
    );

    mod12 modulo4 (
       .clk_in(clk_in),
       .rst_in(rst_mod || rst_in),
       .good_data_in(midi_burst_change_in),
       .note_number_in(midi_burst_data_in[4][15:8]),
       .val_out(intermed_note[4]),
       .subtractions_out(intermed_oct[4]),
       .done(mod_done[4]));
    
    // sine section
    sine_machine sine0(
      .clk_in(clk_in),
      .rst_in(rst_in),
      .note_number_in(note_value_array[0]),
      .valid_data_in(start_sines[0]),
      .octave_in(octave_count[0]),
      .sig_out(sine_data[0]),
      .sig_change(sine_generated[0]),
      .cycle_wait(cycle_wait_array[0])
   );
   sine_machine sine1(
      .clk_in(clk_in),
      .rst_in(rst_in),
      .note_number_in(note_value_array[1]),
      .valid_data_in(start_sines[1]),
      .octave_in(octave_count[1]),
      .sig_out(sine_data[1]),
      .sig_change(sine_generated[1]),
      .cycle_wait(cycle_wait_array[1])
   );
   sine_machine sine2(
      .clk_in(clk_in),
      .rst_in(rst_in),
      .note_number_in(note_value_array[2]),
      .valid_data_in(start_sines[2]),
      .octave_in(octave_count[2]),
      .sig_out(sine_data[2]),
      .sig_change(sine_generated[2]),
      .cycle_wait(cycle_wait_array[2])
   );
   sine_machine sine3(
      .clk_in(clk_in),
      .rst_in(rst_in || rst_sin),
      .note_number_in(note_value_array[3]),
      .valid_data_in(start_sines[3]),
      .octave_in(octave_count[3]),
      .sig_out(sine_data[3]),
      .sig_change(sine_generated[3]),
      .cycle_wait(cycle_wait_array[3])
   );
   sine_machine sine4(
      .clk_in(clk_in),
      .rst_in(rst_in || rst_sin),
      .note_number_in(note_value_array[4]),
      .valid_data_in(start_sines[4]),
      .octave_in(octave_count[4]),
      .sig_out(sine_data[4]),
      .sig_change(sine_generated[4]),
      .cycle_wait(cycle_wait_array[4])
   );
    always_ff @(posedge clk_in)begin
        state_out <= combine_state;
    end
endmodule

`default_nettype wire
