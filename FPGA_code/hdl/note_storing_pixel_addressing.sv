`timescale 1ns / 1ps
`default_nettype none

`ifdef SYNTHESIS
`define FPATH(X) `"X`"
`else /* ! SYNTHESIS */
`define FPATH(X) `"../../data/X`"
`endif  /* ! SYNTHESIS */


module note_storing_pixel_addressing(
    input wire rst_in,
    input wire clk_in,
    
    input wire [11:0] detected_note_in [4:0],
    input wire [5:0] current_staff_cell_in,
    
    input wire [4:0] [8:0] y_dot_in,
    input wire [8:0]  y_stem_in,
    
    input wire [2:0] sharp_shift_in [4:0],
    input wire [7:0] rhythm_shift_in [4:0],
    input wire [6:0] note_width_in [4:0],

    output logic [15:0] addr_out,
    output logic [15:0] mem_out,
    output logic valid_note_out,
    output logic [11:0] note_memory [4:0][63:0],
    output logic valid_staff_record_out,
    output logic [23:0] check,
    output logic [4:0] note_change_valid,
    output logic [4:0] storing_state_out

);

logic [4:0][11:0] detected_note_test;
always_comb begin
    for (int i = 0; i < 5; i++) begin
        detected_note_test[i] = detected_note_in[i];
    end
end


// STORING PIXELS OF CORRESPONDING NOTES
// this all needs to happen within 3_000_000_000 cycles

localparam STAFF_SHIFT = 66; // top of staff is 141 when not shifted; want to be at 75: 141 - 66 = 75
localparam STAFF_HEIGHT = 35;
localparam [3:0] SIXTEENTH = 1;
localparam [3:0] NULL = 13;
enum logic [4:0] {INIT = 0, IDLE = 1, NOTE = 2, REST = 3, STEM = 4, SPLIT_NOTE = 5, DETECTED = 6} storing_state;

assign storing_state_out = storing_state;

logic [5:0] current_staff_cell_buf;

always_ff @(posedge clk_in) begin
    if (rst_in) begin
        valid_staff_record_out <= 0;
        current_staff_cell_buf <= 0;
    end else begin
        valid_staff_record_out <= (current_staff_cell_in == 63)? 1 : 0;
        current_staff_cell_buf <= current_staff_cell_in;
    end
end

// assign storing_state_out = storing_state;

logic [4:0][8:0] x_start;
logic [4:0] [7:0] y_start; // c0 -> c8 leads to 336 possible y locations
logic [8:0] x_counter, x_out, x_out1, x_out2; // can go up to 80 for notes
logic [7:0] y_counter, y_out, y_out1, y_out2; // can go up to 7 for notes
logic [2:0] note_ind;

logic [15:0] addr_buf1, addr_buf2; 
logic valid_note_buf1, valid_note_buf2;   

logic [4:0] [7:0] y_dot_buf;
logic [7:0]  y_stem_buf;
logic [4:0] sharp_shift_buf [2:0];
logic [4:0] rhythm_shift_buf [7:0];
logic [4:0] note_width_buf [6:0];
logic [11:0] detected_note_buf [4:0];

logic already_drawn;

logic [2:0] rest_measures;

logic [4:0] start_staff_cell;


always_ff @(posedge clk_in) begin
    if (rst_in) begin
        storing_state <= INIT;
        start_staff_cell <= 0;
        
        x_start <= 0;
        y_start <= 0;
        x_counter <= 0;
        y_counter <= 0;

        x_out <= 0;
        x_out1 <= 0;
        x_out2 <= 0;
        y_out <= 0;
        y_out1 <= 0;
        y_out2 <= 0;

        for (int i = 0; i < 5; i ++) begin
            for (int j = 0; j < 64; j++) begin
            note_memory[i][j] <= (j == 0 || j == 80 || j == 160 || j == 240)? 12'hFFF : 12'hDFF; // F is whole rest, D is null value in memory
            end
        end

        image_addr <= 0;
        addr_out <= 0;   
        addr_buf1 <= 0;
        addr_buf2 <= 0;
        
        valid_note_out <= 0;   
        valid_note_buf1 <= 0;   
        valid_note_buf2 <= 0;   
        // check <= 0;
        already_drawn <= 0;
        rest_measures <= 0;
        note_change_valid <= 0;
        note_ind <= 0;

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

                image_addr <= (y_counter + 50) * 265 + (x_counter + 185); // white pixel at address 19874 - white out if no note
                addr_buf1 <= (75 + y_counter) * 320 + (80*rest_measures + x_counter);
                addr_buf2 <= addr_buf1;
                addr_out <= addr_buf2;
                
                valid_note_buf1 <= 1;
                valid_note_buf2 <= valid_note_buf1;
                valid_note_out <= valid_note_buf2;
                
                x_out <= x_counter + 185;
                x_out1 <= x_out;
                x_out2 <= x_out1;

                y_out <= 75 + y_counter;
                y_out1 <= y_out;
                y_out2 <= y_out1;

                storing_state <= (rest_measures == 4)? IDLE : REST;
            end
            IDLE: begin
                already_drawn <= (current_staff_cell_in != current_staff_cell_buf)? 0: already_drawn;

                y_dot_buf <= y_dot_in;
                y_stem_buf <= y_stem_in;
                for (int i = 0; i <  5; i++) begin
                    sharp_shift_buf[i] <= sharp_shift_in[i];
                    rhythm_shift_buf[i] <= rhythm_shift_in[i];
                    note_width_buf[i] <= note_width_in[i];
                    detected_note_buf[i] <= detected_note_in[i];
                end

                check[0] <= detected_note_in[0][7:0] != 8'hFF && detected_note_in[0][11:8] != 0;
                check[1] <= detected_note_in[note_ind][11:8] != (note_memory[note_ind][start_staff_cell[note_ind]][11:8]) && detected_note_in[note_ind][11:8] != SIXTEENTH;
                check[2] <= detected_note_in[note_ind][11:8] != (note_memory[note_ind][current_staff_cell_in][11:8]) && detected_note_in[note_ind][11:8] == SIXTEENTH;
                
                // if there is a note input, want to do something
                // storing_state <= (notes_in[0][7:0] != 8'hFF)? NOTE : REST;
                // If current note rhythm is not the same as the one stored at the start
                if (detected_note_in[0][7:0] != 8'hFF && detected_note_in[0][11:8] != 0 ||
                    detected_note_in[1][7:0] != 8'hFF && detected_note_in[1][11:8] != 0 ||
                    detected_note_in[2][7:0] != 8'hFF && detected_note_in[2][11:8] != 0 ||
                    detected_note_in[3][7:0] != 8'hFF && detected_note_in[3][11:8] != 0 ||
                    detected_note_in[4][7:0] != 8'hFF && detected_note_in[4][11:8] != 0
                ) begin
                    storing_state <= DETECTED;
                end
                
                note_change_valid <= 0;

                valid_note_buf1 <= 0;
                valid_note_buf2 <= valid_note_buf1;
                valid_note_out <= valid_note_buf2;
                addr_buf2 <= addr_buf1;
                addr_out <= addr_buf2;
            end
            DETECTED: begin
                note_ind <= (note_ind == 4)? 0 : note_ind + 1;
                check = {detected_note_buf[note_ind],note_memory[note_ind][current_staff_cell_in]};
                // if there is a change in detected note, AND in this cell cycle nothing has been drawn yet
                if (((detected_note_buf[note_ind][11:8] != (note_memory[note_ind][start_staff_cell[note_ind]][11:8]) && detected_note_in[note_ind][11:8] != SIXTEENTH) ||
                    (detected_note_buf[note_ind][11:8] != (note_memory[note_ind][current_staff_cell_in][11:8]) && detected_note_in[note_ind][11:8] == SIXTEENTH)) && already_drawn == 0) begin // && already_drawn == 0
                    
                    note_change_valid[note_ind] <= 1;
                    
                    // If new note is SIXTEENTH, its the beginning of new note
                    // This occurs if note changes, or if it turns on/off, or if a new measure starts
                    start_staff_cell[note_ind] <= (detected_note_buf[note_ind][11:8] == SIXTEENTH)? current_staff_cell_in : start_staff_cell[note_ind];
                    x_start[note_ind] <= (detected_note_buf[note_ind][11:8] == SIXTEENTH)? current_staff_cell_in * 5 : start_staff_cell[note_ind] * 5;
                    y_start[note_ind] <= y_dot_in[note_ind] - STAFF_SHIFT;

                    if (detected_note_buf[note_ind][11:8] == SIXTEENTH) begin 
                        note_memory[note_ind][current_staff_cell_in][11:8] <= detected_note_buf[note_ind][11:8];
                        note_memory[note_ind][current_staff_cell_in][7:0] <= detected_note_buf[note_ind][7:0];
                    // If just extending duration of any note
                    end else begin 
                        note_memory[note_ind][start_staff_cell[note_ind]][11:8] <= detected_note_buf[note_ind][11:8];
                        note_memory[note_ind][start_staff_cell[note_ind]][7:0] <= detected_note_buf[note_ind][7:0]; // store start to be able to break nulls
                        note_memory[note_ind][current_staff_cell_in][11:8] <= NULL;
                    end
                end else begin
                    note_change_valid[note_ind] <= 0;
                end
                
                valid_note_buf1 <= 0;
                valid_note_buf2 <= valid_note_buf1;
                valid_note_out <= valid_note_buf2;
                addr_buf2 <= addr_buf1;
                addr_out <= addr_buf2;

                storing_state <= (note_ind == 4)? (note_change_valid != 0)? NOTE : IDLE : DETECTED;
            end
            NOTE: begin
                already_drawn <= 1;
                
                note_ind <= (x_counter == (note_width_buf[note_ind] - 1) && y_counter == 6)? (note_ind == 4)? 0 : note_ind + 1: note_ind;
                x_counter <= (x_counter == note_width_buf[note_ind] - 1)? 0: x_counter + 1;
                y_counter <= (x_counter == note_width_buf[note_ind] - 1)? (y_counter == 6)? 0: y_counter + 1 : y_counter;
                image_addr <= (y_counter + sharp_shift_buf[note_ind]) * 265 + (x_counter + rhythm_shift_buf[note_ind]); // white pixel at address 19874 - white out if no note
                
                addr_buf1 <= (y_start[note_ind] + y_counter) * 320 + (x_start[note_ind] + x_counter);
                addr_buf2 <= addr_buf1;
                addr_out <= addr_buf2;
                
                valid_note_buf1 <= 1;//(note_change_valid[note_ind])? 1:0;
                valid_note_buf2 <= valid_note_buf1;
                valid_note_out <= valid_note_buf2;
                
                x_out <= x_start[note_ind] + x_counter;
                x_out1 <= x_out;
                x_out2 <= x_out1;
                y_out <= y_start[note_ind] + y_counter;
                y_out1 <= y_out;
                y_out2 <= y_out1;

                storing_state <= (note_ind == 4)? STEM : NOTE;
            end
            STEM: begin
                already_drawn <= 1;
                
                note_ind <= (x_counter == (note_width_buf[note_ind] - 1) && y_counter == 17)? (note_ind == 4)? 0 : note_ind + 1: note_ind;
                x_counter <= (x_counter == note_width_buf[note_ind] - 1)? 0: x_counter + 1;
                y_counter <= (x_counter == note_width_buf[note_ind] - 1)? (y_counter == 17)? 0: y_counter + 1 : y_counter;
                image_addr <= (note_memory[note_ind][start_staff_cell[note_ind]][3:0] < 5)? (14 + y_counter) * 265 + (x_counter + rhythm_shift_buf[note_ind]) :
                                                                              (32 + y_counter) * 265 + (x_counter + rhythm_shift_buf[note_ind]); // white pixel at address 19874 - white out if no note
                
                addr_buf1 <=  (note_memory[note_ind][start_staff_cell[note_ind]][3:0] < 5)? (y_stem_buf[note_ind] - 18 + y_counter - STAFF_SHIFT) * 320 + (x_start[note_ind] + x_counter) :
                                                                             (y_stem_buf[note_ind] + 7 + y_counter- STAFF_SHIFT) * 320 + (x_start[note_ind] + x_counter);
                addr_buf2 <= addr_buf1;
                addr_out <= addr_buf2;
                
                valid_note_buf1 <= 1;//(note_change_valid[note_ind])? 1:0;
                valid_note_buf2 <= valid_note_buf1;
                valid_note_out <= valid_note_buf2;
                
                x_out <= (x_start[note_ind] + x_counter);
                x_out1 <= x_out;
                x_out2 <= x_out1;
                y_out <= (note_memory[note_ind][start_staff_cell[note_ind]][3:0] < 5)? (y_stem_buf[note_ind] - 18 + y_counter- STAFF_SHIFT):(y_stem_buf[note_ind] + 7 + y_counter- STAFF_SHIFT);
                y_out1 <= y_out;
                y_out2 <= y_out1;

                storing_state <= (note_ind == 4)? IDLE : STEM;
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
