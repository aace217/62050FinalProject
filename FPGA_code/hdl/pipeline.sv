`timescale 1ns / 1ps
`default_nettype none

module pipeline #(
        parameter PIPE_SIZE = 10,
        parameter STAGES_NEEDED
    )(
        input wire clk_in,
        input wire [PIPE_SIZE-1:0] wire_in,
        output logic [PIPE_SIZE-1:0] wire_pipe_out [STAGES_NEEDED-1:0]
    );

    always_ff @(posedge clk_in)begin
    wire_pipe_out[0] <= wire_in;
    for (int i=1; i<STAGES_NEEDED; i = i+1)begin
        wire_pipe_out[i] <= wire_pipe_out[i-1];
    end
    end
endmodule

`default_nettype wire
