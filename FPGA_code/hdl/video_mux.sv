`timescale 1ns / 1ps
`default_nettype none

module video_mux(
  input wire clk_in,
  input wire [1:0] bg_in, //regular video
  input wire [15:0] staff_pixel_in,
  input wire staff_pixel_val,
  input wire [15:0] camera_pixel_in,
  input wire camera_pixel_val,
  input wire [7:0] y_in,  //y channel of ycrcb camera conversion
  input wire thresholded_pixel_in, //
  input wire crosshair_in,
  output logic [15:0] pixel_out,
  output logic valid_out
);

  always_ff @(posedge clk_in) begin
    
    case(bg_in)
      0: begin // staff
        pixel_out <= staff_pixel_in;
        valid_out <= staff_pixel_val;
      end
      1: begin // camera
        pixel_out <= camera_pixel_in;
        valid_out <= camera_pixel_val;
      end
      2: begin // another camerea
        pixel_out <= camera_pixel_in;
        valid_out <= camera_pixel_val;
      end
      3: begin // camera with crosshair and mask
        pixel_out = (crosshair_in)? 16'h07e0 : (thresholded_pixel_in)? 16'hFBB5 : {y_in[7:3],y_in[7:2],y_in[7:3]}; 
        valid_out <= camera_pixel_val;    
      end
    endcase
  end

endmodule

`default_nettype wire
