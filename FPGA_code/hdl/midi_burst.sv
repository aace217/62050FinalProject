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
    output logic [31:0] burst_notes_on_out [4:0],
    output logic [31:0] burst_notes_off_out [4:0],
    output logic burst_ready_out,
    output logic [2:0] on_msg_count_out,
    output logic [2:0] off_msg_count_out
);

    // purpose of this module is just to be able to get 5 simultaneous notes 
    // from the output of the midi device
    logic [$clog2(BURST_DURATION)-1:0] cycle_count;
    logic [2:0] local_on_msg_count,local_off_msg_count;
    logic [31:0] midi_on_buffer [4:0];
    logic [31:0] midi_off_buffer [4:0];
    logic [31:0] midi_data;
    enum logic [1:0]  {IDLE,COLLECTING,TRANSMITTING} burst_state;
    assign midi_data = {{7'b0,midi_status_in},{4'b0,midi_channel_in},midi_received_note_in,midi_velocity_in};
    always_ff @(posedge clk_in)begin
        if(rst_in)begin
            // reset everything
            burst_ready_out <= 0;
            on_msg_count_out <= 0;
            off_msg_count_out <= 0;
            for(int i = 0; i<5; i = i+1)begin
                burst_notes_on_out[i] <= 0;
                burst_notes_off_out[i] <= 0;
                midi_on_buffer[i] <= 0;
                midi_off_buffer[i] <= 0;
            end
            burst_state <= IDLE;
            cycle_count <= 0;
            local_on_msg_count <= 0;
            local_off_msg_count <= 0;
        end else begin
            case(burst_state)
            IDLE:begin
                if(midi_data_ready_in)begin
                    burst_state <= COLLECTING;
                    // setting to one becuase a message is placed
                    if(midi_status_in)begin
                        local_on_msg_count <= 1;
                        midi_on_buffer[0] <= midi_data;
                    end else begin
                        local_off_msg_count <= 1;
                        midi_off_buffer[0] <= midi_data;
                    end
                end else begin
                    burst_ready_out <= 0;
                    cycle_count <= 0;
                    on_msg_count_out <= 0;
                    off_msg_count_out <= 0;
                    for(int i = 0; i<5; i = i+1)begin
                        burst_notes_off_out[i] <= 0;
                        burst_notes_on_out[i] <= 0;
                    end
                end
            end
            COLLECTING:begin
                cycle_count <= cycle_count + 1;
                if(midi_data_ready_in)begin
                    // need to check the type of message MIDI on or off
                    if(midi_status_in)begin
                        midi_on_buffer[local_on_msg_count] <= midi_data;
                        local_on_msg_count <= local_on_msg_count + 1;
                    end else begin
                        midi_off_buffer[local_off_msg_count] <= midi_data;
                        local_off_msg_count <= local_off_msg_count + 1;
                    end
                end
                if(cycle_count == BURST_DURATION || local_on_msg_count == 5 || local_off_msg_count == 5)begin
                    burst_state <= TRANSMITTING;
                    cycle_count <= 0;
                    local_on_msg_count <= 0;
                    local_off_msg_count <= 0;
                end
            end
            TRANSMITTING:begin
                // transmitting the data that the burst has acquired
                burst_notes_off_out <= midi_off_buffer;
                burst_notes_on_out <= midi_on_buffer;
                on_msg_count_out <= local_on_msg_count;
                off_msg_count_out <= local_off_msg_count;
                burst_ready_out <= 1;
                cycle_count <= 0;
                burst_state <= IDLE;
                for(int i = 0; i<5; i = i+1)begin
                    midi_on_buffer[i] <= 0;
                    midi_off_buffer[i] <= 0;
                end
            end
            default: burst_state <= IDLE;
            endcase
        end

    end

endmodule
`default_nettype wire
