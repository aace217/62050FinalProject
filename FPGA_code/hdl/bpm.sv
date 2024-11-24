`timescale 1ns / 1ps
`default_nettype none

module bpm(
    input wire change_in,
    input wire [7:0] bpm_in,
    input wire rst_in,
    input wire clk_camera_in,
    // input wire valid_override_in, // button on the board
    // input wire measure_in,
    input wire [1:0] set_bpm_in,
    output logic [7:0] bpm_out,
    output logic [14:0] led_out
);

    logic [31:0] cycle_counter;
    logic [6:0] hit_counter;
    logic [1:0] state;
    logic [1:0] prev_set_bpm;

    localparam IDLE = 0;
    localparam BATON = 1;
    localparam OVERRIDE = 2;
    localparam IDLE_COPY = 3;

    always_ff @(posedge clk_camera_in)begin
        if(rst_in)begin
            // reset all the variables
            bpm_out <= 8'd240; // default value of bpm is 60
            cycle_counter <= 0;
            hit_counter <= 0;
            led_out <= 15'b111_1111_1111_1111;
            state <= IDLE;
            prev_set_bpm <= 0;
        end else begin    
            prev_set_bpm <= set_bpm_in;
            case (state)
                IDLE: begin 
                    cycle_counter <= 0;
                    hit_counter <= 0;
                    led_out <= (set_bpm_in == BATON && prev_set_bpm == IDLE)? 15'b111_1111_1111_1111: 0;
                    state <= (prev_set_bpm == BATON && set_bpm_in == BATON)? IDLE: set_bpm_in;
                end
                OVERRIDE: begin // MANUAL OVERRIDE
                    state <= set_bpm_in;
                    bpm_out <= bpm_in;
                    cycle_counter <= 0;
                    led_out <= 0;
                end
                BATON: begin 
                    if(cycle_counter == 3_000_000_000) begin // 200e6 cycles / 1 sec * 15 sec = 3000e6 cycles
                    // done condition
                        bpm_out <= hit_counter<<2; // must multiply by 4 to get bpm for 60 sec
                        hit_counter <= 0;
                        cycle_counter <= 0;
                        led_out <= 15'b111_1111_1111_1111;
                        state <= IDLE;
                    end else if(cycle_counter == 200_000_000 ||  // LED timer/countdown
                                cycle_counter == 400_000_000 || 
                                cycle_counter == 600_000_000 || 
                                cycle_counter == 800_000_000 || 
                                cycle_counter == 1_000_000_000 || 
                                cycle_counter == 1_200_000_000 || 
                                cycle_counter == 1_400_000_000 || 
                                cycle_counter == 1_600_000_000 || 
                                cycle_counter == 1_800_000_000 || 
                                cycle_counter == 2_000_000_000 || 
                                cycle_counter == 2_200_000_000 || 
                                cycle_counter == 2_400_000_000 || 
                                cycle_counter == 2_600_000_000 || 
                                cycle_counter == 2_800_000_000 
                    ) begin
                        state <= set_bpm_in;
                        led_out <= led_out >> 1;
                        cycle_counter <= cycle_counter + 1;
                        hit_counter <= (change_in)? hit_counter + 1 : hit_counter;
                    end else begin
                        state <= set_bpm_in;
                        cycle_counter <= cycle_counter + 1;
                        hit_counter <= (change_in)? hit_counter + 1 : hit_counter;
                    end
                end
            endcase
        end
    end




endmodule
`default_nettype wire
