`timescale 1ns / 1ps
`default_nettype none

module note_storing_pixel_addressing(
    input wire rst_in,
    input wire clk_in,
    input logic [11:0] detected_note_out [4:0],
    input logic [4:0] [7:0] y_dot_out,
    input logic [7:0]  y_stem_out,
    input logic [4:0] sharp_shift_out [2:0],
    input logic [4:0] rhythm_shift_out [7:0],
    input logic [4:0] note_width_out [6:0],
    input logic [5:0] current_staff_cell_out,
    input logic [4:0] start_staff_cell_out
);

//________________________________________________________________________
// STORING PIXELS OF CORRESPONDING NOTES
// this all needs to happen within 3_000_000_000 cycles

localparam STAFF_SHIFT = 66; // top of staff is 141 when not shifted; want to be at 75: 141 - 66 = 75
localparam STAFF_HEIGHT = 35;
enum logic [4:0] {INIT = 0, IDLE = 1, NOTE = 2, REST = 3, STEM = 4, SPLIT_NOTE = 5} storing_state;

assign storing_state_out = storing_state;

logic [4:0][8:0] x_start;
logic [4:0] [7:0] y_start; // c0 -> c8 leads to 336 possible y locations
logic [8:0] x_counter; // can go up to 80 for notes
logic [7:0] y_counter, y_out, y_out1, y_out2; // can go up to 7 for notes


logic [15:0] addr_buf1, addr_buf2; 
logic valid_note_buf1, valid_note_buf2;   

logic already_drawn;
logic [2:0] rest_measures;


always_ff @(posedge clk_in) begin
    if (rst_in) begin
        storing_state <= INIT;
        start_staff_cell <= 0;
        x_start <= 0;
        y_start <= 0;
        x_counter <= 0;
        y_counter <= 0;
        image_addr <= 0;
        addr_out <= 0;   
        valid_note_out <= 0;   
        num_pixels <= 0;  
        addr_buf2 <= 0;
        addr_out <= 0;
        check <= 0;
        already_drawn <= 0;
    end else begin
        case (storing_state) // all happens within the same current_staff_cell, hopefully
            INIT: begin
                image_addr <= 9;
                x_counter <= (x_counter == 319)? 0: x_counter + 1;
                y_counter <= (x_counter == 319)? (y_counter == 179)? 0: y_counter + 1 : y_counter;
                addr_buf1 <= (y_counter) * 320 + (x_counter);
                addr_buf2 <= addr_buf1;
                addr_out <= addr_buf2;   
                storing_state <= (x_counter == 319 && y_counter == 179)? REST : INIT;
                valid_note_buf1 <= 1;
                valid_note_buf2 <= valid_note_buf1;
                valid_note_out <= valid_note_buf2;
            end
            REST: begin
                rest_measures <= (x_counter == (79) && y_counter == 24)? (rest_measures == 4)? 0 : rest_measures + 1 : rest_measures;
                x_counter <= (x_counter == 79)? 0: x_counter + 1;
                y_counter <= (x_counter == 79)? (y_counter == 24)? 0: y_counter + 1 : y_counter;
                // make a second x y counter for the entire hdmi screen separately; above is counter for image 
                image_addr <= (y_counter + 50) * 265 + (x_counter + 185); // white pixel at address 19874 - white out if no note
                addr_buf1 <= (75 + y_counter) * 320 + (80*rest_measures + x_counter);
                addr_buf2 <= addr_buf1;
                addr_out <= addr_buf2;
                storing_state <= (rest_measures == 4)? IDLE : REST;
                valid_note_buf1 <= 1;
                valid_note_buf2 <= valid_note_buf1;
                valid_note_out <= valid_note_buf2;
                for (int i = 0; i < 5; i ++) begin
                    note_memory[i][current_staff_cell] <= (current_staff_cell == 0 || current_staff_cell == 80 || current_staff_cell == 160 || current_staff_cell == 240)?
                                                          12'hFFF : 12'hDFF; // F is whole rest, D is null value in memory
                end
                y_out <= 75 + y_counter;
                y_out1 <= y_out;
                y_out2 <= y_out1;
            end
            IDLE: begin
                check[0] <= detected_note[0][11:8] == SIXTEENTH;
                check[1] <= detected_note[0][11:8] != note_memory[0][start_staff_cell[0]][11:8];
                check[2] <= already_drawn; //sixteenth_metronome <= (bpm >> 2);
                check[3] <= detected_note[0][7:0] != 8'hFF;
                
                already_drawn <= (current_staff_cell != current_staff_cell_buf)? 0: already_drawn;
                // if there is a note input, want to do something
                if (detected_note[0][7:0] != 8'hFF && detected_note[0][11:8] != 0) begin
                    num_pixels <= 0;
                    // storing_state <= (notes_in[0][7:0] != 8'hFF)? NOTE : REST;
                    // If current note rhythm is not the same as the one stored at the start

                    // if there is a change in detected note, AND in this cell cycle nothing has been drawn yet
                    if (((detected_note[0][11:8] != (note_memory[0][start_staff_cell[0]][11:8]) && detected_note[0][11:8] != SIXTEENTH) ||
                        (detected_note[0][11:8] != (note_memory[0][current_staff_cell][11:8]) && detected_note[0][11:8] == SIXTEENTH)) && already_drawn == 0) begin // && already_drawn == 0
                        storing_state <= NOTE;

                        // If new note is SIXTEENTH, its the beginning of new note
                        // This occurs if note changes, or if it turns on/off, or if a new measure starts
                        start_staff_cell[0] <= (detected_note[0][11:8] == SIXTEENTH)? current_staff_cell : start_staff_cell[0];
                        x_start[0] <= (detected_note[0][11:8] == SIXTEENTH)? current_staff_cell * 5 : start_staff_cell[0] * 5;
                        y_start[0] <= y_dot_buf[0] - STAFF_SHIFT;

                        if (detected_note[0][11:8] == SIXTEENTH) begin 
                            note_memory[0][current_staff_cell][11:8] <= detected_note[0][11:8];
                            note_memory[0][current_staff_cell][7:0] <= detected_note[0][7:0];
                        // If just extending duration of any note
                        end else begin 
                            note_memory[0][start_staff_cell[0]][11:8] <= detected_note[0][11:8];
                            note_memory[0][start_staff_cell[0]][7:0] <= detected_note[0][7:0]; // store start to be able to break nulls
                            note_memory[0][current_staff_cell_buf][11:8] <= NULL;
                        end
                    // else you are waiting for either something to change, or for the next cell
                    end else begin
                        // storing_state <= TRACK;
                        // start_staff_cell[0] <= current_staff_cell;
                    end
                // else, no input note, don't really do anything
                end else begin
                    // start_staff_cell[0] <= current_staff_cell;
                end
                valid_note_buf1 <= 0;
                valid_note_buf2 <= valid_note_buf1;
                valid_note_out <= valid_note_buf2;
                addr_buf2 <= addr_buf1;
                addr_out <= addr_buf2;
            end
            NOTE: begin
                // already_drawn <= 1;
                // num_pixels <= num_pixels + 1;
                x_counter <= (x_counter == note_width_buf2[0] - 1)? 0: x_counter + 1;
                y_counter <= (x_counter == note_width_buf2[0] - 1)? (y_counter == 6)? 0: y_counter + 1 : y_counter;
                // make a second x y counter for the entire hdmi screen separately; above is counter for image 
                image_addr <= (y_counter + sharp_shift_buf2[0]) * 265 + (x_counter + rhythm_shift_buf2[0]); // white pixel at address 19874 - white out if no note
                addr_buf1 <= (y_start[0] + y_counter) * 320 + (x_start[0] + x_counter);
                addr_buf2 <= addr_buf1;
                addr_out <= addr_buf2;
                storing_state <= (x_counter == (note_width_buf2[0] - 1) && y_counter == 6)? STEM : NOTE;
                valid_note_buf1 <= 1;
                valid_note_buf2 <= valid_note_buf1;
                valid_note_out <= valid_note_buf2;
                y_out <= y_start[0] + y_counter;
                y_out1 <= y_out;
                y_out2 <= y_out1;
            end
            STEM: begin
                // already_drawn <= 1;
                // num_pixels <= num_pixels + 1;
                x_counter <= (x_counter == note_width_buf3[0] - 1)? 0: x_counter + 1;
                y_counter <= (x_counter == note_width_buf3[0] - 1)? (y_counter == 17)? 0: y_counter + 1 : y_counter;
                // make a second x y counter for the entire hdmi screen separately; above is counter for image 
                image_addr <= (note_memory[0][start_staff_cell[0]][3:0] < 5)? (14 + y_counter) * 265 + (x_counter + rhythm_shift_buf3[0]) :
                                                                              (32 + y_counter) * 265 + (x_counter + rhythm_shift_buf3[0]); // white pixel at address 19874 - white out if no note
                addr_buf1 <=  (note_memory[0][start_staff_cell[0]][3:0] < 5)? (y_stem[0] - 18 + y_counter - STAFF_SHIFT) * 320 + (x_start[0] + x_counter) :
                                                                             (y_stem[0] + 7 + y_counter- STAFF_SHIFT) * 320 + (x_start[0] + x_counter);
                addr_buf2 <= addr_buf1;
                addr_out <= addr_buf2;
                storing_state <= (x_counter == (note_width_buf3[0] - 1) && y_counter == 17)? IDLE : STEM;
                valid_note_buf1 <= 1;
                valid_note_buf2 <= valid_note_buf1;
                valid_note_out <= valid_note_buf2;
                y_out <= (note_memory[0][start_staff_cell[0]][3:0] < 5)? (y_stem[0] - 18 + y_counter- STAFF_SHIFT):(y_stem[0] + 7 + y_counter- STAFF_SHIFT);
                y_out1 <= y_out;
                y_out2 <= y_out1;
            end
        endcase
    end
end

//________________________________________________________________________
// PIXEL EDITING]][[]]}


logic [14:0] image_addr; // 15 bit addresses
logic [7:0] image_mem; 

xilinx_single_port_ram_read_first #(
    .RAM_WIDTH(8),                       // Specify RAM data width
    .RAM_DEPTH(19875),                     // Specify RAM depth (number of entries)
    .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
    .INIT_FILE(`FPATH(image.mem))          // Specify name/location of RAM initialization file if using one (leave blank if not)
  ) image_BROM (
    .addra(image_addr),     // Address bus, width determined from RAM_DEPTH
    .dina(0),       // RAM input data, width determined from RAM_WIDTH
    .clka(clk_in),       // Clock
    .wea(0),         // Write enable
    .ena(1),         // RAM Enable, for additional power savings, disable port when not in use
    .rsta(rst_in),       // Output reset (does not affect memory contents)
    .regcea(1),   // Output register enable
    .douta(image_mem)      // RAM output data, width determined from RAM_WIDTH
  );


assign mem_out = ((y_out2 == 75 || y_out2 == 81 || y_out2 == 87 || y_out2 == 93 || y_out2 == 99) && (image_mem >= 8'h94))? 16'h0094 : {8'b0, image_mem};
// assign mem_out = image_mem;


endmodule
`default_nettype wire
