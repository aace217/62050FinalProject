`timescale 1ns / 1ps
`default_nettype none

module top_level (
   input wire          clk_100mhz,
   input wire           btn[3:0],
   // seven segment
   output logic [3:0]  ss0_an,//anode control for upper four digits of seven-seg display
   output logic [3:0]  ss1_an,//anode control for lower four digits of seven-seg display
   output logic [6:0]  ss0_c, //cathode controls for the segments of upper four digits
   output logic [6:0]  ss1_c, //cathod controls for the segments of lower four digits

   // midi
   input wire midi_data_in,
   input wire rst_midi
   
);

// Clocking_________________________________________________________________________________
  logic          sys_rst_camera;
  logic          sys_rst_pixel;
  logic          rst_midi;
  logic [31:0]   midi_data_out;

  
  assign sys_rst_camera = btn[0]; //use for resetting camera side of logic
  assign sys_rst_pixel = btn[0]; //use for resetting hdmi/draw side of logic
  assign rst_midi = btn[0]; // use for reseeting midi logic


// MIDI In/Out_________________________________________________________________________________
logic [6:0] ss_c;
logic [7:0] velocity_out,received_note_out;
logic [3:0] channel_out;
logic midi_msg_type,midi_data_ready;
midi_decode midi_decoder(
  .midi_Data_in(midi_data_in),
  .rst_in(rst_midi),
  .clk_in(clk_100mhz),
  .velocity_out(velocity_out),
  .received_note_out(received_note_out),
  .channel_out(channel_out),
  .status(midi_msg_type),
  .data_ready_out(midi_data_ready)
);
always_ff @(posedge clk_100mhz) begin
  if(rst_midi)begin
      val <= 0;
  end else begin
    if(midi_data_ready)begin
        val <= {{7'b0,midi_msg_type},{4'b0,channel_out},received_note_out,velocity_out};
    end
  end
end
// seven segment for debugging
// seven_segment_controller debug_ssc(
//   .clk_in(clk_100mhz),
//   .rst_in(rst_midi),
//   .val_in(val),
//   .cat_out(ss_c),
//   .an_out({ss0_an, ss1_an})
// );
// assign ss0_c = ss_c;
// assign ss1_c = ss_c;
// UART Transmit_________________________________________________________________________________

// Video signal generator_________________________________________________________________________________


endmodule //top_level
`default_nettype wire
