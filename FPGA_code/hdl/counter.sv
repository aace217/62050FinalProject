`default_nettype none // prevents system from inferring an undeclared logic (good practice)

module counter(     input wire clk_in,
                    input wire rst_in,
                    input wire [31:0] period_in,
                    output logic [31:0] count_out
              );

    always_ff @(posedge clk_in)begin
      if (rst_in == 1 || count_out == period_in - 1) begin
        count_out <= 0;
      end else begin
        count_out <= count_out + 1;
      end
    end
      
endmodule

`default_nettype wire
