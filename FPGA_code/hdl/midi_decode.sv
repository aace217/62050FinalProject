`timescale 1ns / 1ps
`default_nettype none
module midi_decode(
    input wire midi_Data_in,
    input wire rst_in,
    input wire clk_in,
    output logic [7:0] velocity_out,
    output logic [7:0] received_note_out,
    output logic [3:0] channel_out,
    output logic status,
    output logic data_ready_out
);
    logic [23:0] msg;
    logic midi_byte_ready;
    logic [7:0] uart_out;
    logic [14:0] cc;
    localparam TIMEOUT_PERIOD = 40*100_000_000/31_250; // if one MIDI packet passes and nothing
                                                       // comes from UART, then something is wrong
    enum logic [1:0]  {IDLE,FIRST_BYTE,SECOND_BYTE, TRANSMITTING} midi_state;
    
    uart_receive #(
        .INPUT_CLOCK_FREQ(100_000_000),
        .BAUD_RATE(31250)
    ) uart_helper(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .rx_wire_in(midi_Data_in),
        .new_data_out(midi_byte_ready),
        .data_byte_out(uart_out)
    );
    always_ff @( posedge clk_in ) begin
        if(rst_in)begin
            // reset all variables
            velocity_out <= 0;
            received_note_out <= 0;
            channel_out <= 0;
            data_ready_out <= 0;
            msg <= 0;
            status <= 0;
            midi_state <= IDLE;
        end else begin 
            case(midi_state)
                IDLE: begin
                    velocity_out <= 0;
                    received_note_out <= 0;
                    channel_out <= 0;
                    data_ready_out <= 0;
                    msg <= 0;
                    status <= 0;
                    cc <= 0;
                    if(midi_byte_ready && uart_out != 8'hf8 && uart_out != 8'hfe && (uart_out == 8'h90 || uart_out == 8'h80))begin  
                    // test condition for if statement tomorrow to only check for on or off messages
                        midi_state <= FIRST_BYTE;
                        msg[7:0] <= uart_out;
                        cc <= 0;
                    end
                end
                FIRST_BYTE:begin
                    if(midi_byte_ready)begin
                        midi_state <= SECOND_BYTE;
                        msg[15:8] <= uart_out;
                        cc <= 0; 
                    end
                    else if(cc > TIMEOUT_PERIOD || uart_out == 8'hf8 || uart_out == 8'hfe)begin
                        midi_state <= IDLE;
                        cc <= 0;
                    end
                    cc <= cc + 1;
                end
                SECOND_BYTE: begin
                    if(midi_byte_ready)begin
                        midi_state <= TRANSMITTING;
                        msg[23:16] <= uart_out;
                        cc <= 0;
                    end
                    else if(cc > TIMEOUT_PERIOD  || uart_out == 8'hf8 || uart_out == 8'hfe)begin
                        midi_state <= IDLE;
                        cc <= 0;
                    end
                    cc <= cc + 1;
                end
                TRANSMITTING: begin
                    // the transmitting state will not be arrived at with bad data
                    // due to previous checks
                    
                    // sending empty data with no note is not allowed
                    // velocity can be empty however (when notes are turned off)
                    if(msg[15:8] != 8'b0)begin
                        channel_out <= msg[3:0]; // those bits indicate the channel #
                        received_note_out <= msg[15:8]; 
                        velocity_out <= msg[23:16];
                        if(msg[23:16] == 0)begin
                            status <= 0;
                        end else begin
                            status <= (msg[7:4] == 4'b1001); // these bits indicate whether note on or off
                        end
                        data_ready_out <= 1;
                    end

                    midi_state <= IDLE;
                end
                default: midi_state <= IDLE;
            endcase
        end
    end
    // Note of test benching:
    // limitation of the test bench: test bench would constantly get stuck in the states
    // we believe that array slicing was the issue
    // module does not get stuck on the FPGA

endmodule
`default_nettype wire
