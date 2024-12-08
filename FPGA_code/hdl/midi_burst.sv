`timescale 1ns / 1ps
`default_nettype none
module midi_burst#(
    parameter BURST_DURATION = 500_000
)(
    input wire [7:0] midi_velocity_in,
    input wire [7:0] midi_received_note_in,
    input wire [3:0] midi_channel_in,
    input wire midi_data_ready_in,
    input wire midi_status_in,
    input wire rst_in,
    input wire clk_in,
    output logic [15:0] burst_notes_out [4:0],
    output logic burst_refresh_out,
    output logic [4:0] note_on_out
);

    // purpose of this module is just to be able to get 5 simultaneous notes 
    // from the output of the midi device
    logic [$clog2(BURST_DURATION)-1:0] cycle_count;
    logic [15:0] midi_data;
    logic [2:0] zero_index;
    logic [2:0] local_msg_count;

    enum logic [1:0]  {IDLE,COLLECTING,TRANSMITTING} burst_state;
    assign midi_data = {midi_received_note_in,midi_velocity_in};

    always_comb begin
        if(note_on_out[4] == 1'b0) begin
            zero_index = 3'b100;
        end else if(note_on_out[3] == 1'b0) begin
            zero_index = 3'b011;
        end else if(note_on_out[2] == 1'b0) begin
            zero_index = 3'b010;
        end else if(note_on_out[1] == 1'b0) begin
            zero_index = 3'b001;
        end else if(note_on_out[0] == 1'b0)begin
            zero_index = 3'b000;
        end else begin
            // if the buffer is full go the fourth
            zero_index = 3'b100;
        end
    end

    always_ff @(posedge clk_in)begin
        if(rst_in)begin
            // reset everything
            burst_refresh_out <= 0;
            local_msg_count <= 0;
            burst_state <= IDLE;
            cycle_count <= 0;
            note_on_out <= 0;
            for(int i = 0; i<5; i = i+1)begin
                burst_notes_out[i] <= 0;
            end
        end else begin
            case(burst_state)
            IDLE:begin
                burst_refresh_out <= 0;
                if(midi_data_ready_in)begin
                    burst_state <= COLLECTING;
                    if(midi_data_ready_in)begin
                        // need to check the type of message MIDI on or off
                        if(midi_status_in)begin
                            // turn a note on
                            burst_notes_out[zero_index] <= midi_data;
                            note_on_out[zero_index] <= 1;
                        end else begin
                            // turn a note off
                            for(int i = 0; i < 5; i = i+1)begin
                                if((burst_notes_out[i][15:8] == midi_data[15:8]))begin
                                    // finding the note
                                    burst_notes_out[i] <= 16'b0;
                                    note_on_out[i] <= 1'b0;
                                end
                            end
                        end
                    end
                end else begin
                    cycle_count <= 0;
                    local_msg_count <= 0;
                end
            end
            COLLECTING:begin
                cycle_count <= cycle_count + 1;
                if(midi_data_ready_in)begin
                    // need to check the type of message MIDI on or off
                    local_msg_count <= local_msg_count + 1;
                    if(midi_status_in)begin
                        // turn a note on
                        burst_notes_out[zero_index] <= midi_data;
                        note_on_out[zero_index] <= 1;
                    end else begin
                        // turn a note off
                        for(int i = 0; i < 5; i = i+1)begin
                            if(burst_notes_out[i][15:8] == midi_data[15:8])begin
                                // finding the note
                                burst_notes_out[i] <= 16'b0;
                                note_on_out[i] <= 1'b0;
                            end
                        end
                    end
                end
                if(cycle_count == BURST_DURATION || (local_msg_count == 5))begin
                    burst_state <= TRANSMITTING;
                    cycle_count <= 0;
                end
            end
            TRANSMITTING:begin
                // transmitting the data that the burst has acquired
                burst_refresh_out <= 1;
                cycle_count <= 0;
                burst_state <= IDLE;
            end
            default: burst_state <= IDLE;
            endcase
        end

    end

endmodule
`default_nettype wire
