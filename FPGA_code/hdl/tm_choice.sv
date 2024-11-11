
module tm_choice (
  input wire [7:0] data_in,
  output logic [8:0] qm_out
  );

  //your code here, friend

  localparam DATA_SIZE = $clog2(8);
  logic [DATA_SIZE:0] one_quantity;

  always_comb begin
    one_quantity = 0;
    for (integer i = 0; i < 8; i++) begin
      one_quantity = (data_in[i] == 1)? one_quantity + 1: one_quantity;
    end

    qm_out[0] = data_in[0];
    if (one_quantity > 4 | (one_quantity == 4 & data_in[0] == 0)) begin
      // option 2
      for (integer i = 1; i < 8; i++) begin
        qm_out[i] = ~(data_in[i] ^ qm_out[i-1]);
      end
      qm_out[8] = 0;
    end else begin
      // option 1
      for (integer i = 1; i < 8; i++) begin
        qm_out[i] = data_in[i] ^ qm_out[i-1];
      end
      qm_out[8] = 1;
    end
  end
endmodule //end tm_choice
