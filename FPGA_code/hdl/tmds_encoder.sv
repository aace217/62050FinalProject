`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)
 
module tmds_encoder(
  input wire clk_in,
  input wire rst_in,
  input wire [7:0] data_in,  // video data (red, green or blue)
  input wire [1:0] control_in, //for blue set to {vs,hs}, else will be 0
  input wire ve_in,  // video data enable, to choose between control or video signal
  output logic [9:0] tmds_out
);
  logic [4:0] n_1;
  logic [4:0] n_0;
  logic [8:0] q_m;
  logic [4:0] cnt; // positive when more ones
 
  tm_choice mtm(
    .data_in(data_in),
    .qm_out(q_m));
 

  always_comb begin
    n_1 = 0;
    for (integer i = 0; i < 8; i++) begin
      n_1 = (rst_in)? 0: ((q_m[i] == 1)? n_1 + 1: n_1);
    end
    n_0 = (rst_in)? 0:8-n_1;
  end

  logic [8:0] qm8check;

  //your code here.
  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      tmds_out <= 0;
      cnt <= 0;
    end else if (ve_in) begin
      if (cnt == 0 | n_1 == 4) begin //running tally == 0 or q_m has equal 1 and 0
        qm8check <= 9'b0;
        tmds_out[9] <= ~q_m[8];
        tmds_out[8] <= q_m[8];
        if (q_m[8] == 0) begin
          tmds_out[7:0] <= ~q_m[7:0];
          cnt <= cnt + (n_0 - n_1); // n_0 - n_1 because a_m[7:0] was inverted
        end else begin
          tmds_out[7:0] <= q_m[7:0];
          cnt <= cnt + (n_1 - n_0);
        end
      end else if ((cnt[4] == 0 & n_1 > n_0) | (cnt[4] == 1 & n_0 > n_1)) begin //too many 0/1 and q_m has more 0/1 respecitvely
        qm8check <= 9'b111111111;
        tmds_out[9] <= 1;
        tmds_out[8] <= q_m[8];
        tmds_out[7:0] <= ~q_m[7:0];
        cnt <= cnt + 2*({4'b0, q_m[8]}) + (n_0 - n_1);
      end else begin
        qm8check <= q_m;
        tmds_out[9] <= 0;
        tmds_out[8] <= q_m[8];
        tmds_out[7:0] <= q_m[7:0];
        cnt <= cnt - 2*({4'b0, ~q_m[8]}) + (n_1 - n_0);
      end
    end else begin
      cnt <= 0;
      case (control_in)
        2'b00: tmds_out <= 10'b1101010100;
        2'b01: tmds_out <= 10'b0010101011;
        2'b10: tmds_out <= 10'b0101010100;
        2'b11: tmds_out <= 10'b1010101011;
      endcase
    end
  end
 
endmodule
 
`default_nettype wire