`timescale 1ns / 1ps
`default_nettype none

module mod12(
        input wire clk_in,
        input wire rst_in,
        input wire good_data_in,
        input wire [7:0] note_number_in,
        output logic [3:0] val_out,
        output logic done,
        output logic [3:0] subtractions_out);
        // combinationally return a number mod 12 and the number of subtractions to get there
        logic [7:0] note_holder;
        enum logic [2:0] {IDLE,CALCULATING, DONE} mod_state;
        always_ff @(posedge clk_in)begin
            if(rst_in)begin
                val_out <= 0;
                subtractions_out <= 0;
                note_holder <= 0;
                done <= 0;
            end else begin
                case(mod_state)
                IDLE: begin
                    if(good_data_in)begin
                        note_holder <= note_number_in;
                        mod_state <= CALCULATING;
                    end else begin
                        note_holder <= 0;
                    end
                    done <= 0;
                    val_out <= 0;
                    subtractions_out <= 0;
                end
                CALCULATING: begin
                    if(note_holder > 11)begin
                        note_holder <= note_holder - 12;
                        subtractions_out <= subtractions_out + 1;
                    end else begin
                        mod_state <= DONE;
                    end
                end
                DONE: begin
                    val_out <= note_holder;
                    done <= 1;
                    mod_state <= IDLE;
                    note_holder <= 0;
                end
                default: mod_state <= IDLE;
                endcase
            end
        end
endmodule

`default_nettype wire