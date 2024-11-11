module video_sig_gen
#(
  parameter ACTIVE_H_PIXELS = 1280,
  parameter H_FRONT_PORCH = 110,
  parameter H_SYNC_WIDTH = 40,
  parameter H_BACK_PORCH = 220,
  parameter ACTIVE_LINES = 720,
  parameter V_FRONT_PORCH = 5,
  parameter V_SYNC_WIDTH = 5,
  parameter V_BACK_PORCH = 20,
  parameter FPS = 60)
(
  input wire pixel_clk_in,
  input wire rst_in,
  output logic [$clog2(TOTAL_PIXELS)-1:0] hcount_out,
  output logic [$clog2(TOTAL_LINES)-1:0] vcount_out,
  output logic vs_out, //vertical sync out
  output logic hs_out, //horizontal sync out
  output logic ad_out,
  output logic nf_out, //single cycle enable signal
  output logic [5:0] fc_out); //frame

  localparam TOTAL_PIXELS = ACTIVE_H_PIXELS + H_FRONT_PORCH + H_SYNC_WIDTH + H_BACK_PORCH; //figure this out
  localparam TOTAL_LINES = ACTIVE_LINES + V_FRONT_PORCH + V_SYNC_WIDTH + V_BACK_PORCH; //figure this out
  logic [$clog2(TOTAL_PIXELS)-1:0] hcount;
  logic [$clog2(TOTAL_LINES)-1:0] vcount;
  
  // a counter of some sort tracking the pixels being iterated through in a frame...
  
  always_comb begin
    hcount_out = hcount;
    vcount_out = vcount;
    vs_out = ((vcount >= ACTIVE_LINES+V_FRONT_PORCH) & (vcount < ACTIVE_LINES+V_FRONT_PORCH+V_SYNC_WIDTH))? 1:0;
    hs_out = ((hcount >= ACTIVE_H_PIXELS+H_FRONT_PORCH) & (hcount <ACTIVE_H_PIXELS+H_FRONT_PORCH+H_SYNC_WIDTH))? 1:0;
    ad_out = (hcount < ACTIVE_H_PIXELS & vcount < ACTIVE_LINES & ~rst_in)? 1:0;
    nf_out = (hcount == ACTIVE_H_PIXELS & vcount == ACTIVE_LINES)? 1:0; 
    fc_out = (hcount == ACTIVE_H_PIXELS & vcount == ACTIVE_LINES)? ((fc_out == FPS-1)? 0:fc_out+1): fc_out;

  end


  always_ff @(posedge pixel_clk_in) begin
    if (rst_in) begin
      hcount <= 0;
      vcount <= 0;
    end 
    else begin
      hcount <= (hcount == TOTAL_PIXELS-1)? 0:hcount + 1;
      vcount <= (hcount == TOTAL_PIXELS-1)? ((vcount == TOTAL_LINES - 1)? 0: vcount + 1): vcount;
    end
  end

endmodule
