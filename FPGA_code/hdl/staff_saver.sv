`default_nettype none // prevents system from inferring an undeclared logic (good practice)

module staff_saver(   
            input wire clk_in,
            input wire rst_in,
            input wire record_in,
            input wire valid_staff_record_in,
            input wire [11:0] note_memory [4:0] [63:0],
            output logic [7:0] midi_velocity_record_out,
            output logic [7:0] midi_received_note_record_out,
            output logic midi_data_ready_record_out,
            output logic midi_status_record_out
            );
    localparam MIDI_BAUD_RATE = 31250;
    localparam CLOCK_FREQUENCY = 100_000_000;
    localparam FREQ_RATIO = MIDI_BAUD_RATE/CLOCK_FREQUENCY;
    logic [$clog2(FREQ_RATIO)-1:0] cycle_wait;
    logic [11:0] note_memory_buf [4:0] [63:0];
    logic [11:0] last_line [4:0];
    logic ram_write;
    logic [2:0] note_number_addr;
    logic [5:0] note_cell_addr;
    logic [11:0] ram_data_in;
    logic [11:0] ram_data_out;
    logic [7:0] midi_vel_buf1,midi_vel_buf2;
    logic [7:0] midi_note_buf1,midi_note_buf2;
    logic midi_valid_buf1,midi_valid_buf2;
    logic midi_status_buf1,midi_status_buf2;

    assign ram_data = note_memory_buf[note_number_addr][note_cell_addr];

    enum logic [1:0] {IDLE,STORE_MEM,READ_MEM} record_state;
    always_ff @(posedge clk_in)begin
        if(rst_in)begin
            midi_velocity_record_out <= 0;
            midi_received_note_record_out <= 0;
            midi_data_ready_record_out <= 0;
            midi_status_record_out <= 0;
            ram_write <= 0;
            cycle_wait <= 0;
            record_state <= IDLE;
        end else begin
            case(record_state)
                IDLE: begin
                    if(valid_staff_record_in)begin
                        record_state <= READMEM;
                        note_memory_buf <= note_memory;
                        note_number_addr <= 0;
                        note_cell_addr <= 0;
                        midi_vel_buf1 <= 0;
                        midi_vel_buf2 <= 0;
                        midi_note_buf1 <= 0;
                        midi_note_buf2 <= 0;
                        cycle_wait <= 0;
                        ram_write <= 1;
                    end
                end
                STORE_MEM: begin
                    // go through the data buffer and save all of its information
                    // in the BRAM
                    if(note_cell_addr == 64)begin
                        record_state <= READ_MEM;
                    end else begin
                        if(note_number_addr == 5)begin
                            note_number_addr = 0;
                            note_cell_addr <= note_cell_addr + 1;
                        end else begin
                            note_number_addr <= note_number_addr + 1;
                        end
                    end
                end
                READ_MEM: begin
                    // go through mem addresses in the same order
                    // to read the data that was stored
                    // Data Format:
                    // [3:0] octave
                    // [7:4] note_kind (A,B,C)
                    // [11:8] note_duration_type (sixteenth) (not used)
                    if(valid_staff_record_in)begin
                        record_state <= READMEM;
                        note_memory_buf <= note_memory;
                        note_number_addr <= 0;
                        note_cell_addr <= 0;
                        midi_vel_buf1 <= 0;
                        midi_vel_buf2 <= 0;
                        midi_note_buf1 <= 0;
                        midi_note_buf2 <= 0;
                        cycle_wait <= 0;
                        ram_write <= 1;
                    end else begin
                        if(record_in)begin
                            if(note_number_addr == 4 && note_cell_addr == 63)begin
                                // going to keep outputting the data
                                note_number_addr = 0;
                                note_cell_addr = 0;
                            end else begin
                                if(note_number_addr == 5)begin
                                    note_number_addr = 0;
                                    note_cell_addr <= note_cell_addr + 1;
                                end else begin
                                    // implement logic for the status bit
                                    if(cycle_wait == FREQ_RATIO-1)begin
                                        note_number_addr <= note_number_addr + 1; // incrementing
                                        midi_vel_buf1 <= 127;
                                        midi_note_buf1 <= 12*ram_data_out[3:0]+ram_data_out[7:4];
                                        if(last_line[note_number_addr][7:0] == ram_data_out[7:0])begin
                                            // no note change so note stays on
                                            midi_status_buf1 <= 1;
                                        end else begin
                                            // this means there was a note status change
                                            // note off
                                            midi_status_buf1 <= 0;
                                        end
                                        last_line[note_number_addr] <= ram_data_out;
                                        cycle_wait <= 0;
                                    end else begin
                                        cycle_wait <= cycle_wait + 1;
                                    end
                                end
                            end
                            midi_vel_buf2 <= midi_vel_buf1;
                            midi_velocity_record_out <= midi_vel_buf2;

                            midi_note_buf2 <= midi_note_buf1;
                            midi_received_note_record_out <= midi_note_buf2;
                            
                            midi_status_buf2 <= midi_status_buf1;
                            midi_status_record_out <= midi_status_buf2;
                        end
                    end
                end

                default: record_state <= IDLE;
            endcase
        end
    end

    blk_mem_gen_0 staff_storer (
    .addra(note_number_addr + 5*note_cell_addr), //pixels are stored using this math
    .clka(clk_in),
    .wea(ram_write),
    .dina(ram_data_in),
    .ena(1'b1),
    .douta(), //never read from this side
    .addrb(note_number_addr + 5*note_cell_addr),//transformed lookup pixel
    .dinb(16'b0), // no data is going into the b side
    .clkb(clk_in),
    .web(1'b0), // b side is not being written to
    .enb(1'b1),
    .doutb(ram_data_out)
  );
endmodule

`default_nettype wire
