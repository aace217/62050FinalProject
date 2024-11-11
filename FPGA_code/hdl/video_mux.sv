`timescale 1ns / 1ps
`default_nettype none

module video_mux(
  input wire bg_in, //regular video
  input wire [23:0] camera_pixel_in, //16 bits from camera 5:6:5
  input wire [1:0] staff_pixel_in, //16 bits from camera 5:6:5
  input wire [7:0] camera_y_in,  //y channel of ycrcb camera conversion
  input wire [7:0] channel_in, //the channel from selection module
  input wire thresholded_pixel_in, //
  input wire crosshair_in,
  output logic [23:0] pixel_out
);
endmodule

`default_nettype wire
