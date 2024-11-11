`timescale 1ns / 1ps
`default_nettype none

module top_level (
   input wire          clk_100mhz,
   output logic [15:0] led,
   // camera bus
   input wire [7:0]    camera_d, // 8 parallel data wires
   output logic        cam_xclk, // XC driving camera
   input wire          cam_hsync, // camera hsync wire
   input wire          cam_vsync, // camera vsync wire
   input wire          cam_pclk, // camera pixel clock
   inout wire          i2c_scl, // i2c inout clock
   inout wire          i2c_sda, // i2c inout data
   input wire [15:0]   sw,  
   input wire [3:0]    btn, 
   output logic [2:0]  rgb0,
   output logic [2:0]  rgb1, 
   // seven segment
   output logic [3:0]  ss0_an,//anode control for upper four digits of seven-seg display
   output logic [3:0]  ss1_an,//anode control for lower four digits of seven-seg display
   output logic [6:0]  ss0_c, //cathode controls for the segments of upper four digits
   output logic [6:0]  ss1_c, //cathod controls for the segments of lower four digits
   // hdmi port
   output logic [2:0]  hdmi_tx_p, //hdmi output signals (positives) (blue, green, red)
   output logic [2:0]  hdmi_tx_n, //hdmi output signals (negatives) (blue, green, red)
   output logic        hdmi_clk_p, hdmi_clk_n, //differential hdmi clock
   // speakers
   output logic        spkl, spkr, // left and right channels of line out port
   input wire          cipo, // SPI controller-in peripheral-out
   output logic        copi, dclk, cs, // SPI controller output signals
   // uart
   input wire 				 uart_rxd, // UART computer-FPGA
   output logic 			 uart_txd // UART FPGA-computer
);

   // shut up those RGBs
   assign rgb0 = 0;
   assign rgb1 = 0;

// Clocking_________________________________________________________________________________
   logic          sys_rst_camera;
   logic          sys_rst_pixel;

   logic          clk_camera;
   logic          clk_pixel;
   logic          clk_5x;
   logic          clk_xc;

   logic          clk_100_passthrough;

   cw_hdmi_clk_wiz wizard_hdmi
      (.sysclk(clk_100_passthrough),  // input
       .reset(0),                      // input
       .clk_pixel(clk_pixel),          // output
       .clk_tmds(clk_5x)              // output
      );                    

   cw_fast_clk_wiz wizard_migcam
      (.clk_in1(clk_100mhz),          // input
       .reset(0),                      // input
       .clk_camera(clk_camera),        // output
       .clk_xc(clk_xc),                // output
       .clk_100(clk_100_passthrough)   // output
      );                    

   assign cam_xclk = sw[1] ? clk_xc : 1'b0;

   assign sys_rst_camera = btn[0]; //use for resetting camera side of logic
   assign sys_rst_pixel = btn[0]; //use for resetting hdmi/draw side of logic

// Pixel Reconstruct_________________________________________________________________________________

   // synchronizers to prevent metastability
   logic [7:0]    camera_d_buf [1:0];
   logic          cam_hsync_buf [1:0];
   logic          cam_vsync_buf [1:0];
   logic          cam_pclk_buf [1:0];

   always_ff @(posedge clk_camera) begin
      camera_d_buf <= {camera_d, camera_d_buf[1]};
      cam_pclk_buf <= {cam_pclk, cam_pclk_buf[1]};
      cam_hsync_buf <= {cam_hsync, cam_hsync_buf[1]};
      cam_vsync_buf <= {cam_vsync, cam_vsync_buf[1]};
   end

   logic [10:0] camera_hcount;
   logic [9:0]  camera_vcount;
   logic [15:0] camera_pixel;
   logic        camera_valid;

   pixel_reconstruct camera_pixel_receiver
      (.clk_in(clk_camera),
      .rst_in(sys_rst_camera),
      .camera_pclk_in(cam_pclk_buf[0]),
      .camera_hs_in(cam_hsync_buf[0]),
      .camera_vs_in(cam_vsync_buf[0]),
      .camera_data_in(camera_d_buf[0]),
      .pixel_valid_out(camera_valid),
      .pixel_hcount_out(camera_hcount),
      .pixel_vcount_out(camera_vcount),
      .pixel_data_out(camera_pixel)
      );

   logic [15:0] val_cam_pixel;
   assign val_cam_pixel = (camera_valid)? camera_pixel: 16'b0;

// Color channel_________________________________________________________________________________

logic [9:0] y_full, cr_full, cb_full; //ycrcb conversion of full pixel
logic [7:0] cam_red, cam_green, cam_blue;

assign cam_red = (camera_valid)? {camera_pixel[15:11], 3'b0}: 8'b0;
assign cam_green = (camera_valid)? {camera_pixel[10:4], 3'b0}: 8'b0;
assign cam_blue = (camera_valid)? {camera_pixel[4:0], 3'b0}: 8'b0;

rgb_to_ycrcb rgbtoycrcb_m (
   .clk_in(clk_camera),
   .r_in(cam_red),
   .g_in(cam_green),
   .b_in(cam_blue),
   .y_out(y_full),
   .cr_out(cr_full),
   .cb_out(cb_full)
);

//threshold module (apply masking threshold):
logic [7:0] lower_threshold;
logic [7:0] upper_threshold;
logic mask; //Whether or not thresholded pixel is 1 or 0

// hardcoding pink color detection 
assign lower_threshold = 8'hA0;
assign lower_threshold = 8'hF0;

// hardcoding cr channel, no channel_select module!
logic [7:0] selected_channel;
logic [7:0] y_channel;
assign cr_channel = {!cr_full[7],cr_full[6:0]}; 
assign y_channel = y_full[7:0];

//Thresholder: Takes in the full selected channedl and
//based on upper and lower bounds provides a binary mask bit
// * 1 if selected channel is within the bounds (inclusive)
// * 0 if selected channel is not within the bounds
threshold mt(
   .clk_in(clk_camera),
   .rst_in(sys_rst_camera),
   .pixel_in(selected_channel),
   .lower_bound_in(lower_threshold),
   .upper_bound_in(upper_threshold),
   .mask_out(mask) //single bit if pixel within mask.
);

// Crosshairs
logic [7:0] ch_red, ch_green, ch_blue;
always_comb begin
   ch_red   = ((camera_vcount==y_com) || (camera_hcount==x_com))?8'hFF:8'h00;
   ch_green = ((camera_vcount==y_com) || (camera_hcount==x_com))?8'hFF:8'h00;
   ch_blue  = ((camera_vcount==y_com) || (camera_hcount==x_com))?8'hFF:8'h00;
end


// Seven segment controller_________________________________________________________________________________
logic [6:0] ss_c;
//modified version of seven segment display for showing
// thresholds and selected channel
// special customized version
lab05_ssc mssc(.clk_in(clk_camera),
               .rst_in(sys_rst_camera),
               .lt_in(lower_threshold),
               .ut_in(upper_threshold),
               .channel_sel_in(channel_sel),
               .cat_out(ss_c),
               .an_out({ss0_an, ss1_an})
);
assign ss0_c = ss_c; //control upper four digit's cathodes!
assign ss1_c = ss_c; //same as above but for lower four digits!

// Center of mass_________________________________________________________________________________

  center_of_mass com_m(
    .clk_in(clk_camera),
    .rst_in(sys_rst_camera),
    .x_in(camera_hcount), 
    .y_in(camera_vcount),
    .valid_in(mask), //aka threshold
    .tabulate_in(camera_hcount==1279 && camera_vcount==719), // need to change
    .x_out(x_com_calc),
    .y_out(y_com_calc),
    .valid_out(new_com)
  );
  //grab logic for above
  //update center of mass x_com, y_com based on new_com signal
  always_ff @(posedge clk_camera)begin
    if (sys_rst_pixel)begin
      x_com <= 0;
      y_com <= 0;
    end if(new_com)begin
      x_com <= x_com_calc;
      y_com <= y_com_calc;
    end
  end

// Baton tracker & BPM_________________________________________________________________________________

logic [1:0] set_bpm;
logic [1:0] set_bpm_buf;
assign set_bpm = sw[3:2];
// sw == 00: don't set bpm
// sw == 01: set bpm with baton
// sw == 10: set bpm with switches 15-8
always_ff @(posedge clk_camera) begin
   set_bpm_buf <= set_bpm; // buffering 1 cycle for the cycle between baton_tracker and bpm
end

logic beat_detected;
logic [7:0] bpm;
logic [7:0] manual_bpm;
assign manual_bpm =  sw[15:8];

baton_tracker my_bt
( .y_com_in(y_com),
  .measure_in(set_bpm == 2'b01),
  .rst_in(sys_rst_camera),
  .clk_camera_in(clk_c),
  .change_out(beat_detected)
);

bpm gen_bpm 
( .change_in(beat_detected),
  .bpm_in(manual_bpm),
  .rst_in(sys_rst_camera),
  .clk_camera_in(clk_camera),
  .valid_override_in(set_bpm_buf == 2'b10),
  .measure_in(set_bpm_buf == 2'b01),
  .bpm_out(bpm)
);

// MIDI In/Files_________________________________________________________________________________

logic [79:0] received_note_out;

// Staff Creation & Image Sprite_________________________________________________________________________________

staff_creation my_staff 
( .hcount(camera_hcount),
  .vcount(camera_vcount),
  .bpm(bpm),
  .received_note(received_note_out),
  .clk_camera_in(clk_camera),
  .rst_in(sys_rst_camera),
  .staff_out(staff_pixel),
  .staff_valid(staff_val)
);

// UART Transmit_________________________________________________________________________________

// Video signal generator_________________________________________________________________________________

logic          hsync_hdmi;
logic          vsync_hdmi;
logic [10:0]  hcount_hdmi;
logic [9:0]    vcount_hdmi;
logic          active_draw_hdmi;
logic          new_frame_hdmi;
logic [5:0]    frame_count_hdmi;
logic          nf_hdmi;

video_sig_gen vsg
   (.pixel_clk_in(clk_pixel),
   .rst_in(sys_rst_pixel),
   .hcount_out(hcount_hdmi),
   .vcount_out(vcount_hdmi),
   .vs_out(vsync_hdmi),
   .hs_out(hsync_hdmi),
   .nf_out(nf_hdmi),
   .ad_out(active_draw_hdmi),
   .fc_out(frame_count_hdmi)
   );

// Frame Buffer_________________________________________________________________________________

localparam FB_DEPTH = 320*180;
localparam FB_SIZE = $clog2(FB_DEPTH); // 15
logic [FB_SIZE-1:0] addra; //used to specify address to write to in frame buffer

logic valid_camera_mem; //used to enable writing pixel data to frame buffer
logic [1:0] camera_mem; //used to pass pixel data into frame buffer; black & white

logic [1:0] frame_buff_raw; //data out of frame buffer; black & white
logic [FB_SIZE-1:0] addrb; //used to lookup address in memory for reading from buffer
logic good_addrb; //used to indicate within valid frame for scaling

always_ff @(posedge clk_camera)begin
   // addra logic
   if (camera_vcount[1:0] == 0 && camera_hcount[1:0] == 0 && staff_valid) begin // every 4 addresses are "valid" for 4x downscaling
      valid_camera_mem <= staff_valid;
      addra <= {5'b0, (camera_vcount>>2)}*320 + {4'b0,(camera_hcount>>2)};
      camera_mem <= staff_pixel;
   end else begin
      valid_camera_mem <= 0;
   end

   //addrb logic
   addrb <= {5'b0, vcount_hdmi>>2}*320 + {4'b0,hcount_hdmi>>2};
   good_addrb <=(hcount_hdmi<1280)&&(vcount_hdmi<720);
end

//frame buffer from IP
blk_mem_gen_0 frame_buffer (
   .addra(addra), //pixels are stored using this math
   .clka(clk_camera),
   .wea(valid_camera_mem),
   .dina(camera_mem),
   .ena(1'b1),
   .douta(), //never read from this side
   .addrb(addrb),//transformed lookup pixel
   .dinb(16'b0),
   .clkb(clk_pixel),
   .web(1'b0),
   .enb(1'b1),
   .doutb(frame_buff_raw)
);

// HDMI Video Out_________________________________________________________________________________

// Video Mux: select from the different display modes based on switch values
//used with switches for display selections
logic [1:0] display_choice;
logic [1:0] target_choice;

assign display_choice = sw[4];


video_mux mvm(
   .bg_in(display_choice), //choose background
   .camera_pixel_in({cam_red, cam_green, cam_blue}), //TODO: needs (PS2)
   .staff_pixel_in(staff_pixel), //TODO: needs (PS2)
   .camera_y_in(y_channel), //luminance TODO: needs (PS6)
   .channel_in(cr_channel), //current channel being drawn TODO: needs (PS5)
   .thresholded_pixel_in(mask), //one bit mask signal TODO: needs (PS4)
   .crosshair_in({ch_red, ch_green, ch_blue}), //TODO: needs (PS8)
   .pixel_out({red,green,blue}) //output to tmds
);

// HDMI Output: just like before!

logic [9:0] tmds_10b [0:2]; //output of each TMDS encoder!
logic       tmds_signal [2:0]; //output of each TMDS serializer!

//three tmds_encoders (blue, green, red)
//note green should have no control signal like red
//the blue channel DOES carry the two sync signals:
//  * control_in[0] = horizontal sync signal
//  * control_in[1] = vertical sync signal

tmds_encoder tmds_red(
      .clk_in(clk_pixel),
      .rst_in(sys_rst_pixel),
      .data_in(red),
      .control_in(2'b0),
      .ve_in(active_draw_hdmi_pipe[7]),
      .tmds_out(tmds_10b[2]));

tmds_encoder tmds_green(
      .clk_in(clk_pixel),
      .rst_in(sys_rst_pixel),
      .data_in(green),
      .control_in(2'b0),
      .ve_in(active_draw_hdmi_pipe[7]),
      .tmds_out(tmds_10b[1]));

tmds_encoder tmds_blue(
      .clk_in(clk_pixel),
      .rst_in(sys_rst_pixel),
      .data_in(blue),
      .control_in({vsync_hdmi_pipe[7],hsync_hdmi_pipe[7]}),
      .ve_in(active_draw_hdmi_pipe[7]),
      .tmds_out(tmds_10b[0]));


//three tmds_serializers (blue, green, red):
tmds_serializer red_ser(
      .clk_pixel_in(clk_pixel),
      .clk_5x_in(clk_5x),
      .rst_in(sys_rst_pixel),
      .tmds_in(tmds_10b[2]),
      .tmds_out(tmds_signal[2]));
tmds_serializer green_ser(
      .clk_pixel_in(clk_pixel),
      .clk_5x_in(clk_5x),
      .rst_in(sys_rst_pixel),
      .tmds_in(tmds_10b[1]),
      .tmds_out(tmds_signal[1]));
tmds_serializer blue_ser(
      .clk_pixel_in(clk_pixel),
      .clk_5x_in(clk_5x),
      .rst_in(sys_rst_pixel),
      .tmds_in(tmds_10b[0]),
      .tmds_out(tmds_signal[0]));

   //output buffers generating differential signals:
   //three for the r,g,b signals and one that is at the pixel clock rate
   //the HDMI receivers use recover logic coupled with the control signals asserted
   //during blanking and sync periods to synchronize their faster bit clocks off
   //of the slower pixel clock (so they can recover a clock of about 742.5 MHz from
   //the slower 74.25 MHz clock)
   OBUFDS OBUFDS_blue (.I(tmds_signal[0]), .O(hdmi_tx_p[0]), .OB(hdmi_tx_n[0]));
   OBUFDS OBUFDS_green(.I(tmds_signal[1]), .O(hdmi_tx_p[1]), .OB(hdmi_tx_n[1]));
   OBUFDS OBUFDS_red  (.I(tmds_signal[2]), .O(hdmi_tx_p[2]), .OB(hdmi_tx_n[2]));
   OBUFDS OBUFDS_clock(.I(clk_pixel), .O(hdmi_clk_p), .OB(hdmi_clk_n));


   // Nothing To Touch Down Here:
   // register writes to the camera

   // The OV5640 has an I2C bus connected to the board, which is used
   // for setting all the hardware settings (gain, white balance,
   // compression, image quality, etc) needed to start the camera up.
   // We've taken care of setting these all these values for you:
   // "rom.mem" holds a sequence of bytes to be sent over I2C to get
   // the camera up and running, and we've written a design that sends
   // them just after a reset completes.

   // If the camera is not giving data, press your reset button.

   logic  busy, bus_active;
   logic  cr_init_valid, cr_init_ready;

   logic  recent_reset;
   always_ff @(posedge clk_camera) begin
      if (sys_rst_camera) begin
         recent_reset <= 1'b1;
         cr_init_valid <= 1'b0;
      end
      else if (recent_reset) begin
         cr_init_valid <= 1'b1;
         recent_reset <= 1'b0;
      end else if (cr_init_valid && cr_init_ready) begin
         cr_init_valid <= 1'b0;
      end
   end

   logic [23:0] bram_dout;
   logic [7:0]  bram_addr;

   // ROM holding pre-built camera settings to send
   xilinx_single_port_ram_read_first
     #(
       .RAM_WIDTH(24),
       .RAM_DEPTH(256),
       .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
       .INIT_FILE("rom.mem")
       ) registers
       (
        .addra(bram_addr),     // Address bus, width determined from RAM_DEPTH
        .dina(24'b0),          // RAM input data, width determined from RAM_WIDTH
        .clka(clk_camera),     // Clock
        .wea(1'b0),            // Write enable
        .ena(1'b1),            // RAM Enable, for additional power savings, disable port when not in use
        .rsta(sys_rst_camera), // Output reset (does not affect memory contents)
        .regcea(1'b1),         // Output register enable
        .douta(bram_dout)      // RAM output data, width determined from RAM_WIDTH
        );

   logic [23:0] registers_dout;
   logic [7:0]  registers_addr;
   assign registers_dout = bram_dout;
   assign bram_addr = registers_addr;

   logic       con_scl_i, con_scl_o, con_scl_t;
   logic       con_sda_i, con_sda_o, con_sda_t;

   // NOTE these also have pullup specified in the xdc file!
   // access our inouts properly as tri-state pins
   IOBUF IOBUF_scl (.I(con_scl_o), .IO(i2c_scl), .O(con_scl_i), .T(con_scl_t) );
   IOBUF IOBUF_sda (.I(con_sda_o), .IO(i2c_sda), .O(con_sda_i), .T(con_sda_t) );

   // provided module to send data BRAM -> I2C
   camera_registers crw
     (.clk_in(clk_camera),
      .rst_in(sys_rst_camera),
      .init_valid(cr_init_valid),
      .init_ready(cr_init_ready),
      .scl_i(con_scl_i),
      .scl_o(con_scl_o),
      .scl_t(con_scl_t),
      .sda_i(con_sda_i),
      .sda_o(con_sda_o),
      .sda_t(con_sda_t),
      .bram_dout(registers_dout),
      .bram_addr(registers_addr));

   // a handful of debug signals for writing to registers
   assign led[0] = crw.bus_active;
   assign led[1] = cr_init_valid;
   assign led[2] = cr_init_ready;
   assign led[15:3] = 0;

endmodule


`default_nettype wire
