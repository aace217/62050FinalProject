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
   // input wire          cipo, // SPI controller-in peripheral-out
   // output logic        copi, dclk, cs, // SPI controller output signals
   // uart
   // input wire 				 uart_rxd, // UART computer-FPGA
   output logic 			 uart_txd, // UART FPGA-computer

   // midi
   input wire midi_data_in
);

   // shut up those RGBs
   assign rgb0 = 0;
   assign rgb1 = 0;

// Clocking_________________________________________________________________________________
   logic          sys_rst_camera;
   logic          sys_rst_pixel;

   logic          clk_camera;
   logic          clk_pixel_raw;
   logic          clk_pixel;
   logic          clk_5x;
   logic          clk_xc;

   logic          clk_100_passthrough;

   cw_hdmi_clk_wiz wizard_hdmi
      (.sysclk(clk_100_passthrough),  // input
       .reset(0),                      // input
       .clk_pixel(clk_pixel_raw),          // output
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
   assign clk_pixel = sw[2] ? clk_pixel_raw : 1'b0;

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

   logic [8:0] camera_hcount;
   logic [7:0]  camera_vcount;
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
   always_ff @(posedge clk_camera) begin
      val_cam_pixel <= (camera_valid)? camera_pixel: val_cam_pixel;
   end

   logic [8:0] camera_hcount_pipe [15:0];
   logic [7:0]  camera_vcount_pipe [15:0];
   logic [15:0] val_cam_pixel_pipe [15:0];
   logic        camera_valid_pipe [16:0];
   
   pipeline #(
   .PIPE_SIZE(1),
   .STAGES_NEEDED(17)
   ) camera_valid_piper (
   .clk_in(clk_camera),
   .wire_in(camera_valid),
   .wire_pipe_out(camera_valid_pipe)
   );

   pipeline #(
   .PIPE_SIZE(16),
   .STAGES_NEEDED(16)
   ) val_cam_pixel_piper (
   .clk_in(clk_camera),
   .wire_in(val_cam_pixel),
   .wire_pipe_out(val_cam_pixel_pipe)
   );

   pipeline #(
   .PIPE_SIZE(9),
   .STAGES_NEEDED(16)  // 12 for now since staff creation is unknown, but will have at least 4 cycles
   ) camera_hcount_piper (
   .clk_in(clk_camera),
   .wire_in(camera_hcount),
   .wire_pipe_out(camera_hcount_pipe)
   );

   pipeline #(
   .PIPE_SIZE(8),
   .STAGES_NEEDED(16) // 12 for now since staff creation is unknown, but will have at least 4 cycles
   ) camera_vcount_piper (
   .clk_in(clk_camera),
   .wire_in(camera_vcount),
   .wire_pipe_out(camera_vcount_pipe)
   );

   //logic [6:0] ss_c; //used to grab output cathode signal for 7s leds

   // seven_segment_controller pixel_display_test
   // (.clk_in(clk_camera),
   // .rst_in(sys_rst_camera),
   // // .val_in({5'b0,camera_hcount, 6'b0, camera_vcount}),
   // .val_in({camera_d_buf[0], 4'b0, 3'b0, cam_pclk, 3'b0, cam_pclk_buf[0], 3'b0, cam_hsync_buf[0], 3'b0, cam_vsync_buf[0], 3'b0, cam_xclk}),
   // .cat_out(ss_c),
   // .an_out({ss0_an, ss1_an})
   // );

   // assign ss0_c = ss_c; //control upper four digit's cathodes!
   // assign ss1_c = ss_c; //same as above but for lower four digits!


// Color channel_________________________________________________________________________________

   logic [9:0] y_full, cr_full, cb_full; //ycrcb conversion of full pixel
   logic [7:0] cam_red, cam_green, cam_blue;

   always_ff @(posedge clk_camera) begin
      cam_red <= (camera_valid)? {camera_pixel[15:11], 3'b0}: cam_red;
      cam_green <= (camera_valid)? {camera_pixel[10:5], 2'b0}: cam_green;
      cam_blue <= (camera_valid)? {camera_pixel[4:0], 3'b0}: cam_blue;
   end

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
   assign lower_threshold = 8'b10100000; // may also consider x90 for a more lenient max
   assign upper_threshold = 8'hF0;

   // hardcoding cr channel, no channel_select module!
   logic [7:0] cr_channel;
   logic [7:0] y_channel;
   assign cr_channel = {!cr_full[7],cr_full[6:0]}; 
   assign y_channel = y_full[7:0];

   logic [7:0] y_channel_pipe [12:0];

   pipeline #(
   .PIPE_SIZE(8),
   .STAGES_NEEDED(13)
   ) y_channel_piper (
   .clk_in(clk_camera),
   .wire_in(y_channel),
   .wire_pipe_out(y_channel_pipe)
   );

   //Thresholder: Takes in the full selected channedl and
   //based on upper and lower bounds provides a binary mask bit
   // * 1 if selected channel is within the bounds (inclusive)
   // * 0 if selected channel is not within the bounds
   threshold mt(
      .clk_in(clk_camera),
      .rst_in(sys_rst_camera),
      .pixel_in(cr_channel),
      .lower_bound_in(lower_threshold),
      .upper_bound_in(upper_threshold),
      .mask_out(mask) //single bit if pixel within mask.
   );
   
   logic mask_pipe [11:0];

   pipeline #(
   .PIPE_SIZE(1),
   .STAGES_NEEDED(12)
   ) mask_piper (
   .clk_in(clk_camera),
   .wire_in(mask),
   .wire_pipe_out(mask_pipe)
   );



// Seven segment controller_________________________________________________________________________________
   // logic [6:0] ss_c;
   //modified version of seven segment display for showing
   // thresholds and selected channel
   // special customized version
   // lab05_ssc mssc(.clk_in(clk_camera),
   //                .rst_in(sys_rst_camera),
   //                .lt_in({camera_d_buf[0]}), //lower_threshold
   //                .ut_in({3'b0, cam_hsync_buf[0],3'b0, cam_vsync_buf[0]}), //upper_threshold
   //                .channel_sel_in(3'b101),
   //                .cat_out(ss_c),
   //                .an_out({ss0_an, ss1_an})
   // );
   // assign ss0_c = ss_c; //control upper four digit's cathodes!
   // assign ss1_c = ss_c; //same as above but for lower four digits!

// Center of mass_________________________________________________________________________________

   logic [9:0] x_com, x_com_calc; //long term x_com and output from module, resp
   logic [8:0] y_com, y_com_calc; //long term y_com and output from module, resp
   logic new_com; //used to know when to update x_com and y_com ...
 

   center_of_mass com_m(
      .clk_in(clk_camera),
      .rst_in(sys_rst_camera),
      .x_in(camera_hcount_pipe[4]), 
      .y_in(camera_vcount_pipe[4]),
      .valid_in(mask), //aka threshold
      .tabulate_in(camera_hcount_pipe[4]==319 && camera_vcount_pipe[4]==179), // need to change
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

      
   // Crosshairs
   logic [7:0] ch_red, ch_green, ch_blue;
   always_comb begin
      ch_red   = ((camera_vcount_pipe[5]==y_com) || (camera_hcount_pipe[5]==x_com))?8'hFF:8'h00;
      ch_green = ((camera_vcount_pipe[5]==y_com) || (camera_hcount_pipe[5]==x_com))?8'hFF:8'h00;
      ch_blue  = ((camera_vcount_pipe[5]==y_com) || (camera_hcount_pipe[5]==x_com))?8'hFF:8'h00;
   end

   logic [7:0] ch_red_pipe [10:0];
   logic [7:0] ch_green_pipe [10:0];
   logic [7:0] ch_blue_pipe [10:0];

   pipeline #(
   .PIPE_SIZE(8),
   .STAGES_NEEDED(11)
   ) ch_red_piper (
   .clk_in(clk_camera),
   .wire_in(ch_red),
   .wire_pipe_out(ch_red_pipe)
   );

   pipeline #(
   .PIPE_SIZE(8),
   .STAGES_NEEDED(11)
   ) ch_green_piper (
   .clk_in(clk_camera),
   .wire_in(ch_green),
   .wire_pipe_out(ch_green_pipe)
   );

   pipeline #(
   .PIPE_SIZE(8),
   .STAGES_NEEDED(11)
   ) ch_blue_piper (
   .clk_in(clk_camera),
   .wire_in(ch_blue),
   .wire_pipe_out(ch_blue_pipe)
   );


// Baton tracker & BPM_________________________________________________________________________________

   logic [1:0] set_bpm;
   logic [1:0] set_bpm_buf;
   logic record_on;
   logic valid_staff_record_out;
   assign record_on = sw[0];
   assign set_bpm = sw[6:5];
   // sw == 00: don't set bpm
   // sw == 01: set bpm with baton
   // sw == 10: set bpm with switches 15-8
   always_ff @(posedge clk_camera) begin
      set_bpm_buf <= set_bpm; // buffering 1 cycle for the cycle between baton_tracker and bpm
   end

   logic beat_detected;
   logic [7:0] bpm, bpm_buf;
   logic [7:0] manual_bpm;
   assign manual_bpm =  sw[15:8];


   // testing
   logic [3:0] total_beats_detected;
   always_ff @(posedge clk_camera) begin 
      bpm_buf <= bpm;
      if (sys_rst_camera) begin
         total_beats_detected <= 0;
      end else begin 
         total_beats_detected <= total_beats_detected + beat_detected;
      end
   end

   baton_tracker my_bt
   ( .y_in(y_com),
   .measure_in(set_bpm == 2'b01),
   .rst_in(sys_rst_camera),
   .clk_camera_in(clk_camera),
   .change_out(beat_detected)
   );

   bpm gen_bpm 
   ( .change_in(beat_detected),
   .bpm_in(manual_bpm),
   .rst_in(sys_rst_camera),
   .clk_camera_in(clk_camera),
   .set_bpm_in(set_bpm_buf),
   .bpm_out(bpm),
   .led_out(led[14:0])
   );

// UART Transmit_________________________________________________________________________________

   logic [7:0] to_transmit;
   logic [15:0] raw_message;
   logic [15:0] full_message;
   logic new_message;
   logic uart_busy;
   logic [15:0] uart_count;
   logic beat_existed;
   logic data_ready;

   // assign uart_count = (camera_vcount_pipe[4])*320 + (camera_hcount_pipe[4]);

   counter uart_counter (
      .clk_in(clk_camera),
      .rst_in(sys_rst_camera),
      .period_in(57600),
      .count_out(uart_count)
   );

   always_ff @(posedge clk_camera) begin
      if (uart_count == 14400 && data_ready == 0) begin
         to_transmit <= y_com[7:0];
         beat_existed <= beat_existed | beat_detected;
         data_ready <= 1;
      end else if (uart_count == 43200 && data_ready == 0) begin
         to_transmit <= {beat_existed, 7'b0};
         beat_existed <= beat_detected;
         data_ready <= 1;
      end else begin
         beat_existed <= beat_existed | beat_detected;
         data_ready <= 0;
      end
   end

   //sampling one of every two data points... may need to be changed
   // always_ff @(posedge clk_camera) begin
   //    if (sys_rst_camera) begin
   //       new_message <= 1;
   //       raw_message <= {y_com, 4'b0, beat_detected}; // updates every cycle
   //       uart_counter <= 0;
   //    end else begin
   //       if (uart_counter == 0) begin
   //          to_transmit <= full_message[15:8];
   //          full_message <= (new_message)? {y_com, 4'b0, beat_detected}: full_message << 8;
   //          new_message <= !new_message;
   //       end
   //       uart_counter <= (uart_counter == 9)? 0 : uart_counter + 1;
   //    end
   // end

   uart_transmit #( // parameters copied from lab 3, potentially need to be changed
      .INPUT_CLOCK_FREQ(200000000),
      .BAUD_RATE(230400)
   ) my_uart (
      .clk_in(clk_camera),
      .rst_in(sys_rst_camera),
      .data_byte_in(to_transmit),
      .trigger_in(data_ready),
      .busy_out(uart_busy),
      .tx_wire_out(uart_txd)
      );

// MIDI In/Files_________________________________________________________________________________
   logic [20:0] measured_val; // for easy display on an ssd
   logic [7:0] velocity_out,received_note_out;
   logic [3:0] channel_out;
   logic midi_msg_type,midi_data_ready;
   logic [15:0] burst_on [4:0];
   logic [20:0] burst_off [4:0];
   logic [20:0] ss_var [4:0];
   logic burst_change;
   logic [23:0] debug;
   logic [10:0] count;
   logic [2:0] on_count,off_count;
   logic only_off;
   logic [4:0] note_on_out;
   logic data_check;
   logic [7:0] midi_velocity_record_out,midi_received_note_record_out;
   logic record_data_ready;
   logic record_data_midi_status;

   midi_decode midi_decoder(
      .midi_Data_in(midi_data_in),
      .rst_in(sys_rst_camera),
      .clk_in(clk_100_passthrough),
      .velocity_out(velocity_out),
      .received_note_out(received_note_out),
      .channel_out(channel_out),
      .status(midi_msg_type),
      .data_ready_out(midi_data_ready)
   );

   // the below module is modeled after midi_burst
   staff_saver replayer(
      .clk_in(clk_100_passthrough),
      .rst_in(sys_rst_camera),
      .record_in(record_on),
      .valid_staff_record_in(valid_staff_record_out),
      .note_memory(note_memory), // from note_storing_run_it_back
      .midi_velocity_record_out(midi_velocity_record_out), 
      .midi_received_note_record_out(midi_received_note_record_out),
      .midi_data_ready_record_out(record_data_ready),
      .midi_status_record_out(record_data_midi_status)
   );

   // note that midi_burst will not always take BURST_DURATION CYCLES
   // If it receives 5 notes before BURST_DURATION CYCLES,
   // then it will output its data
   midi_burst #(.BURST_DURATION(750_000)) note_collector(
      .midi_velocity_in((record_on)?midi_velocity_record_out:velocity_out),
      .midi_received_note_in((record_on)?midi_received_note_record_out:received_note_out),
      .midi_channel_in((record_on)?0:channel_out),
      .midi_data_ready_in((record_on)?record_data_ready:midi_data_ready),
      .midi_status_in((record_on)?record_data_midi_status:midi_msg_type),
      .rst_in(sys_rst_camera),
      .clk_in(clk_100_passthrough),
      .burst_notes_out(burst_on),
      .burst_refresh_out(burst_change),
      .note_on_out(note_on_out)
   );
//seven segment for debugging
// logic [6:0] ss_c;

// PWM Output_________________________________________________________________________________
// Assuming we will get at most five notes together from the module after midi_decode
// For now, just working with one midi note to output

   logic [7:0] sound_wave;
   logic [7:0] midi_note_copy;
   logic [7:0] note_pitch;
   logic [7:0] note_octave;

   always_comb begin
      midi_note_copy = received_note_out;
      note_octave = 0;
      for (int i = 0; i < 11; i ++) begin
         if (midi_note_copy > 11) begin
            midi_note_copy = midi_note_copy - 12;
            note_octave = note_octave + 1;
         end
      end
      note_pitch = midi_note_copy[3:0];
   end

   // and then some sort of bram to get sound wave from input note note_pitch
   // sample it based off note_octave, put into sound_wave

   logic spk_out;
   logic pwm_ready;
   logic valid_sig_data;
   logic [2:0] debug_state;
   logic [2:0] msg_cnt;
   logic [7:0] pwm_in;
   logic [31:0] val;
   logic [7:0] wait_val;
   logic [2:0] mods_done;
   logic [3:0] octave_count [4:0];
   logic [3:0] note_value_array [4:0];
   logic [7:0] note_velocity_array [4:0];
   logic [4:0] pwm_on_array;

   pwm_combine synth(
      .clk_in(clk_100_passthrough),
      .rst_in(sys_rst_camera),
      .midi_burst_change_in(burst_change),
      .on_array_in(note_on_out),
      .midi_burst_data_in(burst_on),
      .octave_count(octave_count),
      .note_value_array(note_value_array),
      .note_velocity_array(note_velocity_array),
      .midi_data_parsed_ready_out(valid_sig_data),
      .pwm_data_ready_out(pwm_ready),
      .pwm_data_out(sound_wave),
      .on_array_out(pwm_on_array)      
      // ,.state_out(debug_state)
      // ,.msg_count(msg_cnt)
      // ,.mods_done(mods_done)
   );

   always_ff @(posedge clk_100_passthrough)begin
      // if(pwm_ready)begin
      //    pwm_in <= sound_wave;
      // end
      val <= count;
      if((sound_wave == 0) && (pwm_ready == 0))begin
         count <= count + 1;
         pwm_in <= 0;
      end else begin
         pwm_in <= sound_wave;
      end
   
      // if(burst_change)begin
      //    val  <= note_on_out;
      // end
      if(valid_sig_data)begin
         //val <= {mods_done,1'b0,msg_cnt,note_on_out[4:1],sound_wave,octave_count[4],note_value_array[4],1'b0,debug_state};
         
      end
   end
   
//    logic [6:0] ss_c;
// seven_segment_controller debug_ssc(
//   .clk_in(clk_100_passthrough),
//   .rst_in(sys_rst_camera),
//   .val_in(val),
//   .cat_out(ss_c),
//   .an_out({ss0_an, ss1_an})
// );
// assign ss0_c = ss_c;
// assign ss1_c = ss_c;

   pwm audio_out
   (.clk_in(clk_100_passthrough),
   .rst_in(sys_rst_camera),
   .dc_in(pwm_in),
   .sig_out(spk_out)
   );

   // set both output channels equal to the same PWM signal!
   assign spkl = spk_out;
   assign spkr = spk_out;
// Staff Creation & Image Sprite_________________________________________________________________________________

   logic [7:0] notes [4:0];
   logic [31:0] durations [4:0];
   logic [11:0] note_memory [4:0][63:0];

   // testing with fake midi signals
   logic [3:0] octave_draw_in [4:0];
   logic [3:0] note_draw_in [4:0];
   logic valid_draw_in;
   logic [4:0] note_on_draw_in;
   logic [3:0] btn_clean;

   debouncer btn_deb (
      .clk_in(clk_100_passthrough),
      .rst_in(sys_rst_camera),
      .dirty_in(btn[1]),
      .clean_out(btn_clean)
   );

   always_comb begin
      if (sw[7]) begin
         note_on_draw_in[4] = (btn_clean)? 1 : 0;
         note_on_draw_in[1] = 0;
         note_on_draw_in[2] = (btn[2])? 1 : 0;
         note_on_draw_in[3] = (btn[3])? 1 : 0;
         note_on_draw_in[0] = 0;

         octave_draw_in[4] = (btn_clean)? 5 : 0;
         octave_draw_in[1] = 0;
         octave_draw_in[2] = (btn[2])? 4 : 0;
         octave_draw_in[3] = (btn[3])? 4 : 0;
         octave_draw_in[0] = 0;
      
         note_draw_in[4] = (btn_clean)? 2 : 0;
         note_draw_in[1] = 0;
         note_draw_in[2] = (btn[2])? 9 : 0;
         note_draw_in[3] = (btn[3])? 6 : 0;
         note_draw_in[0] = 0;
         
         valid_draw_in = 1;
      end else begin
         for (int i = 0;i < 5; i++) begin
            octave_draw_in[i] = octave_count[i];
            note_draw_in[i] = note_value_array[i];
         end

         note_on_draw_in = note_on_out;
         valid_draw_in = valid_sig_data;
      end
   // 1 cycle
   end

   note_duration_run_it_back get_notes (
      .octave_count(octave_draw_in),
      .note_value_array(note_draw_in),
      .bpm(bpm_buf),
      .valid_note_in(valid_draw_in),
      .note_on_in(note_on_draw_in),
      .clk_in(clk_100_passthrough),
      .rst_in(sys_rst_camera),
      .notes_out(notes),
      .durations_out(durations)
   );
   
   logic [15:0] addra_note;
   logic [15:0] note_mem;
   logic [31:0] met_test;
   logic [5:0] staff_cell;
   logic [3:0] storing_state, storing_state_check;

   logic [3:0] note_rhythms [4:0];
   logic [4:0][5:0] start_staff_cell;

   logic valid_note_pixel;
   logic [11:0] detected_note [4:0];
   logic [12:0] num_pixels;

   logic [3:0] check;
   logic [3:0] storing_state_out_test;

   note_storing_run_it_back eom (
      .clk_in(clk_100_passthrough),
      .rst_in(sys_rst_camera),
      .bpm(bpm_buf),
      .num_lines(1),
      .notes_in(notes),
      .durations_in(durations),
      .addr_out(addra_note),
      .mem_out(note_mem),
      .valid_note_out(valid_note_pixel),
      .note_memory(note_memory),
      .valid_staff_record_out(valid_staff_record_out),
      .sixteenth_metronome(met_test),
      .current_staff_cell(),
      .current_staff_cell_buf(staff_cell),
      .storing_state_out(storing_state),
      .storing_state_out_test(storing_state_out_test),
      .note_rhythms(note_rhythms),
      .start_staff_cell(start_staff_cell),
      .detected_note(detected_note),
      .num_pixels(num_pixels),
      .check(check)
  );

   logic [15:0] addrb_bram;
   always_ff @(posedge clk_camera) begin
      addrb_bram <= camera_vcount_pipe[14]*320+camera_hcount_pipe[14];
   end

   //frame buffer from IP
   blk_mem_gen_0 frame_buffer_midi (
      .addra(addra_note), //pixels are stored using this math
      .clka(clk_100_passthrough),
      .wea(valid_note_pixel),
      .dina(note_mem),
      .ena(1'b1),
      .douta(), //never read from this side
      .addrb(addrb_bram), //transformed lookup pixel, NEED TO PIPELINE TODO
      .dinb(16'b0),
      .clkb(clk_camera),
      .web(1'b0),
      .enb(1'b1),
      .doutb(staff_pixel)
   );


   logic [15:0] staff_pixel, staff_pixel_buf;
   logic staff_val, staff_val_buf;

   // staff_creation my_staff 
   // ( .hcount(camera_hcount_pipe[7]),
   // .vcount(camera_vcount_pipe[7]),
   // .bpm(bpm),
   // .notes_in(notes),
   // .durations_in(durations),
   // .clk_camera_in(clk_camera),
   // .rst_in(sys_rst_camera),
   // .staff_out(staff_pixel),
   // .staff_valid(staff_val)
   // );

   always_ff @(posedge clk_camera)begin
      if (sys_rst_camera) begin
         storing_state_check <= 0;
         staff_val <= 1;
      end else begin
      // staff_pixel_buf <= staff_pixel;
         staff_val <= 1;
         // staff_val_buf <= staff_val;
         
         storing_state_check <= storing_state_check + storing_state;
      end

   end
   
   logic [6:0] ss_c; //used to grab output cathode signal for 7s leds

   seven_segment_controller pixel_display_test
   (.clk_in(clk_100_passthrough),
   .rst_in(sys_rst_camera),
   // .val_in({5'b0,camera_hcount, 6'b0, camera_vcount}),
   .val_in({staff_cell, bpm_buf}),
   .cat_out(ss_c),
   .an_out({ss0_an, ss1_an})
   );

   assign ss0_c = ss_c; //control upper four digit's cathodes!
   assign ss1_c = ss_c; //same as above but for lower four digits!



// Video signal generator_________________________________________________________________________________

   logic          hsync_hdmi;
   logic          vsync_hdmi;
   logic [10:0]  hcount_hdmi;
   logic [9:0]    vcount_hdmi;
   logic [10:0]  hcount_hdmi_buf;
   logic [9:0]    vcount_hdmi_buf;
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

   always_ff @(posedge clk_pixel) begin
      hcount_hdmi_buf <= hcount_hdmi;
      vcount_hdmi_buf <= vcount_hdmi;
   end

// Video MUX _________________________________________________________________________________

 // Video Mux: select from the different display modes based on switch values
   //used with switches for display selections

   logic [1:0] target_choice;
   logic [1:0] display_choice;
   assign display_choice = sw[4:3];

   // logic [7:0]          red,green,blue;
   // logic [23:0]          video_mux_out;

   // to send to BRAM
   logic valid_mem;
   logic [15:0] pixel_mem;

   video_mux mvm(
      .clk_in(clk_camera),
      .bg_in(display_choice), //choose background
      .staff_pixel_in(staff_pixel),
      .staff_pixel_val(staff_val),
      .camera_pixel_in(val_cam_pixel_pipe[15]),
      .camera_pixel_val(camera_valid_pipe[16]),
      .y_in(y_channel_pipe[12]), // luminance
      .thresholded_pixel_in(mask_pipe[12]), // one bit mask signal
      .crosshair_in({ch_red_pipe[10], ch_green_pipe[10], ch_blue_pipe[10]}), 
      .pixel_out(pixel_mem),
      .valid_out(valid_mem)
   );


// Frame Buffer _________________________________________________________________________________

   localparam FB_DEPTH = 320*180;
   localparam FB_SIZE = $clog2(FB_DEPTH); // 15
   logic [FB_SIZE-1:0] addra; //used to specify address to write to in frame buffer
   logic [FB_SIZE-1:0] addrb; //used to lookup address in memory for reading from buffer
   logic [FB_SIZE-1:0] addra_buf; //used to specify address to write to in frame buffer
   logic [FB_SIZE-1:0] addrb_buf; //used to lookup address in memory for reading from buffer
   logic good_addrb; //used to indicate within valid frame for scaling

   logic [15:0] frame_buff_raw; //data out of frame buffer; black & white
   logic [15:0] frame_buff_valid; //data out of frame buffer; black & white

   always_ff @(posedge clk_camera) begin
      // addra logic
      addra <= {5'b0, (camera_vcount_pipe[15])}*320 + {4'b0,(camera_hcount_pipe[15])};
      addra_buf <= addra;
   end

   always_ff @(posedge clk_pixel) begin
      //addrb logic
      addrb <= {5'b0, vcount_hdmi_buf>>2}*320 + {4'b0,hcount_hdmi_buf>>2};
      good_addrb <=(hcount_hdmi_buf<1280)&&(vcount_hdmi_buf<720);
      addrb_buf <= addrb;
   end

   // logic [FB_SIZE-1:0] addra_cam; //used to specify address to write to in frame buffer

   // logic valid_camera_mem; //used to enable writing pixel data to frame buffer
   // logic [15:0] camera_mem; //used to pass pixel data into frame buffer; black & white

   // logic [15:0] frame_buff_raw; //data out of frame buffer; black & white
   // logic [FB_SIZE-1:0] addrb_cam; //used to lookup address in memory for reading from buffer
   // logic good_addrb_cam; //used to indicate within valid frame for scaling

   // logic [FB_SIZE-1:0] addra_cam_buf; //used to lookup address in memory for reading from buffer
   // logic [FB_SIZE-1:0] addrb_cam_buf; //used to lookup address in memory for reading from buffer


   //frame buffer from IP
   blk_mem_gen_0 frame_buffer_cam (
      .addra(addra_buf), //pixels are stored using this math
      .clka(clk_camera),
      .wea(valid_mem),
      .dina(pixel_mem),
      .ena(1'b1),
      .douta(), //never read from this side
      .addrb(addrb_buf),//transformed lookup pixel
      .dinb(16'b0),
      .clkb(clk_pixel),
      .web(1'b0),
      .enb(1'b1),
      .doutb(frame_buff_raw)
   );

   logic addrbp1, addrbp2;
   logic [7:0] red, green, blue;

   always_ff @(posedge clk_pixel)begin
      addrbp1 <= good_addrb;
      addrbp2 <= addrbp1;
      frame_buff_valid <= addrbp2? frame_buff_raw:16'b0;
   end

   always_comb begin
      if (display_choice == 0) begin
         red = frame_buff_valid[7:0];
         green = frame_buff_valid[7:0];
         blue = frame_buff_valid[7:0];
      end else begin
         red = {frame_buff_valid[15:11], 3'b0};
         green = {frame_buff_raw[10:5], 2'b0};
         blue = {frame_buff_raw[4:0], 3'b0};
      end
   end
   
// HDMI Video Out_________________________________________________________________________________

  



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
         .ve_in(active_draw_hdmi),
         .tmds_out(tmds_10b[2]));

   tmds_encoder tmds_green(
         .clk_in(clk_pixel),
         .rst_in(sys_rst_pixel),
         .data_in(green),
         .control_in(2'b0),
         .ve_in(active_draw_hdmi),
         .tmds_out(tmds_10b[1]));

   tmds_encoder tmds_blue(
         .clk_in(clk_pixel),
         .rst_in(sys_rst_pixel),
         .data_in(blue),
         .control_in({vsync_hdmi,hsync_hdmi}),
         .ve_in(active_draw_hdmi),
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
   // assign led[0] = crw.bus_active;
   // assign led[1] = cr_init_valid;
   // assign led[2] = cr_init_ready;
   // assign led[15:3] = 0;

endmodule // top_level


`default_nettype wire
