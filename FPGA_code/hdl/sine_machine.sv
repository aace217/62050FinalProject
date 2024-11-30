`timescale 1ns / 1ps
`default_nettype none
`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"../data/X`"
`endif  /* ! SYNTHESIS */
module sine_machine(
        input wire clk_in,
        input wire rst_in,
        input wire [5:0] note_number_in,
        input wire [4:0] octave_in,
        input wire valid_data_in,
        input wire only_off_msgs,
        output logic sig_ready,
        output logic [7:0] sig_out);
// formula for CYCLE_WAIT = CLOCK_FREQUENCY*440/(8000*f) where f is the desired frequency
// all the values are precomputed in python
// TODO: Implement something with velocity at some point
// purpose of this module is to take in any of the 128 midi notes
// and output the sine waves for that note
// it will do the appropriate reading rates and stuff to get the correct note
    logic [17:0] sample_count;
    logic [17:0] sample_rate_counter;  // Counter to scale the clock frequency to 440 Hz
    logic [17:0] prelim_cycle_wait; // Number of clock cycles per sample for 440 Hz
    logic [17:0] cycle_wait;
    logic [4:0] octave_hold;
    logic new_data_waiting;
    enum logic [2:0] {IDLE,SETTING_READ_RATE, READING} waveform_state; // do not want to change reading rate mid read
   always_ff @(posedge clk_in)begin
        if(rst_in)begin
            // reset everything
            waveform_state <= IDLE;
            sig_ready <= 0;
            new_data_waiting <= 0;
            sample_count <= 0;
            sample_rate_counter <= 0;
            prelim_cycle_wait <= 0;
            octave_hold <= 0;
        end else begin
            case(waveform_state)
                IDLE: begin
                    sig_ready <= 0;
                    new_data_waiting <= 0;
                    sample_count <= 0;
                    sample_rate_counter <= 0;
                    octave_hold <= 0;
                    if(valid_data_in)begin
                        // you only want to change reading rate when new data comes in
                        waveform_state <= SETTING_READ_RATE;
                        octave_hold <= octave_in;
                        case (note_number_in)
                        // these are precomputed values based on the formula above
                            4'b0000: prelim_cycle_wait <= 42044; // C
                            4'b0001: prelim_cycle_wait <= 39685; // C#
                            4'b0010: prelim_cycle_wait <= 37458; // D
                            4'b0011: prelim_cycle_wait <= 35355; // D#
                            4'b0100: prelim_cycle_wait <= 33371; // E
                            4'b0101: prelim_cycle_wait <= 31498; // F
                            4'b0110: prelim_cycle_wait <= 29731; // F#
                            4'b0111: prelim_cycle_wait <= 28061; // G
                            4'b1000: prelim_cycle_wait <= 26487; // G#
                            4'b1001: prelim_cycle_wait <= 25000; // A
                            4'b1010: prelim_cycle_wait <= 23597; // A#
                            4'b1011: prelim_cycle_wait <= 22273; // B
                            default: prelim_cycle_wait <= 42044; // C
                        endcase
                    end
                end
                SETTING_READ_RATE: begin
                    if(octave_hold < 6)begin
                        cycle_wait <= prelim_cycle_wait << (6-octave_hold);
                    end else if (octave_hold > 6)begin
                        cycle_wait <= prelim_cycle_wait >> (octave_hold-6);
                    end else begin
                        cycle_wait <= prelim_cycle_wait;
                        // if octave_in == 6, then CYCLE_WAIT does not change
                        // becuase that is the 4th octave.
                    end
                    waveform_state <= READING;
                end
                READING: begin
                    // it will be stuck in this state and the next until new data comes in
                    // if(valid_data_in)begin
                    //     new_data_waiting <= 1;

                    // end
                    if(valid_data_in)begin
                        //interrupt when new note comes in
                        sample_count <= 0;
                        prelim_cycle_wait <= 0;
                        waveform_state <= SETTING_READ_RATE;
                        octave_hold <= octave_in;
                        case (note_number_in)
                        // these are precomputed values based on the formula above
                            4'b0000: prelim_cycle_wait <= 42044; // C
                            4'b0001: prelim_cycle_wait <= 39685; // C#
                            4'b0010: prelim_cycle_wait <= 37458; // D
                            4'b0011: prelim_cycle_wait <= 35355; // D#
                            4'b0100: prelim_cycle_wait <= 33371; // E
                            4'b0101: prelim_cycle_wait <= 31498; // F
                            4'b0110: prelim_cycle_wait <= 29731; // F#
                            4'b0111: prelim_cycle_wait <= 28061; // G
                            4'b1000: prelim_cycle_wait <= 26487; // G#
                            4'b1001: prelim_cycle_wait <= 25000; // A
                            4'b1010: prelim_cycle_wait <= 23597; // A#
                            4'b1011: prelim_cycle_wait <= 22273; // B
                            default: prelim_cycle_wait <= 42044; // C
                        endcase
                    end else begin
                        if (sample_count == 8000) begin// Reset the address to the start once it exceeds the memory depth (8000 samples)
                            // done reading the audio file
                            sample_count <= 0;
                            waveform_state <= IDLE;
                            prelim_cycle_wait <= 0;
                            octave_hold <= 0;    
                        end else begin
                            if (sample_rate_counter == cycle_wait - 1) begin
                                sample_rate_counter <= 0;
                                sample_count <= sample_count + 1;  // Increment sample address
                                sig_ready <= 1;  // Signal that data is ready
                            end else begin
                                sample_rate_counter <= sample_rate_counter + 1;
                                sig_ready <= 0;  // Not ready unless the counter hits the sample rate
                            end
                        end
                    end
                    

                end
                default: waveform_state <= IDLE;
            endcase
        end
   end


    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH(8),                       // Specify RAM data width
        .RAM_DEPTH(8000),                    // Specify RAM depth (number of entries)
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
        .INIT_FILE(`FPATH(audio_data.mem))    // Specify name/location of RAM initialization file
    ) image_mem (
        .addra(sample_count),                   // Address bus
        .dina(0),                            // RAM input data (not used in read-only)
        .clka(clk_in),                       // Clock
        .wea(0),                             // Write enable
        .ena(1),                             // RAM Enable
        .rsta(rst_in),                       // Output reset
        .regcea(1),                          // Output register enable
        .douta(sig_out)                      // RAM output data
    );
endmodule

`default_nettype wire