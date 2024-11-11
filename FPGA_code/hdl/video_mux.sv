`timescale 1ns / 1ps
`default_nettype none

module video_mux(
  input wire bg_in, //regular video
  input wire [1:0] staff_pixel_in, //16 bits from camera 5:6:5
  input wire [7:0] camera_y_in,  //y channel of ycrcb camera conversion
  input wire thresholded_pixel_in, //
  input wire crosshair_in,
  output logic [23:0] pixel_out
);

  always_comb begin
    case(bg_in)
      0: pixel_out = (crosshair_in)? 24'h00FF00 : (thresholded_pixel_in != 0) ? 24'hFF77AA : {camera_y_in,camera_y_in,camera_y_in};
      1: pixel_out = {24{staff_pixel_in}};
    endcase
  end

endmodule

`default_nettype wire
