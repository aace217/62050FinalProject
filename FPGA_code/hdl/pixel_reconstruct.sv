`timescale 1ns / 1ps
`default_nettype none

module pixel_reconstruct
	#(
	 parameter HCOUNT_WIDTH = 9,
	 parameter VCOUNT_WIDTH = 8
	 )
	(
	 input wire 										 clk_in,
	 input wire 										 rst_in,
	 input wire 										 camera_pclk_in,
	 input wire 										 camera_hs_in,
	 input wire 										 camera_vs_in,
	 input wire [7:0] 							 		 camera_data_in,
	 output logic 									 	 pixel_valid_out,
	 output logic [HCOUNT_WIDTH-1:0] 					 pixel_hcount_out,
	 output logic [VCOUNT_WIDTH-1:0] 					 pixel_vcount_out,
	 output logic [15:0] 						 		 pixel_data_out
	 );

	 // your code here! and here's a handful of logics that you may find helpful to utilize.
	
	 // previous value of PCLK
	 logic 												 pclk_prev;

	 // can be assigned combinationally:
	 //  true when pclk transitions from 0 to 1
	 logic 												 camera_sample_valid;
	 assign camera_sample_valid = pclk_prev == 0 && camera_pclk_in == 1;
	 
	 // previous value of camera data, from last valid sample!
	 // should NOT update on every cycle of clk_in, only
	 // when samples are valid.
	 logic 												 last_sampled_hs;
	 logic [7:0] 										 last_sampled_data;

	 // flag indicating whether the last byte has been transmitted or not.
	 logic 												 half_pixel_ready;
	 logic [HCOUNT_WIDTH-1:0] 							 hcount_real;

	 always_ff@(posedge clk_in) begin
			if (rst_in) begin
				pixel_valid_out <= 0;
				pixel_hcount_out <= 0;
				pixel_vcount_out <= 0;
				pixel_data_out <= 0;
				pclk_prev <= 0;
				last_sampled_hs <= 0;
				last_sampled_data <= 0;
				half_pixel_ready <= 0;
				hcount_real <= 0;
			end else begin
				pclk_prev <= camera_pclk_in; // this should be correct
				last_sampled_hs <= (camera_sample_valid)? camera_hs_in: last_sampled_hs;
				pixel_valid_out <= 0;
				if (!camera_vs_in && camera_sample_valid) begin
					pixel_hcount_out <= 0;
					hcount_real <= 0;
					pixel_vcount_out <= 0;
					half_pixel_ready <= 0;
					pixel_data_out <= 0;
				end else if (!camera_hs_in && camera_sample_valid) begin
					pixel_hcount_out <= (last_sampled_hs)? 0: hcount_real;
					hcount_real <= (last_sampled_hs)? 0: hcount_real;
					pixel_vcount_out <= (last_sampled_hs)? pixel_vcount_out + 1: pixel_vcount_out;
					half_pixel_ready <= 0;
					pixel_data_out <= 0;
				end else if (camera_sample_valid) begin
					// if not in sync region
					if (half_pixel_ready) begin
						pixel_hcount_out <= hcount_real;
						hcount_real <= hcount_real + 1;
						pixel_data_out <= {last_sampled_data,camera_data_in};
						pixel_valid_out <= 1;
						half_pixel_ready <= 0;
						last_sampled_data <= 0;
					end else begin
						half_pixel_ready <= 1;
						last_sampled_data <= camera_data_in;
					end
				end
			end
	 end

endmodule

`default_nettype wire
