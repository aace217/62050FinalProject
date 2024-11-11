`default_nettype none
module center_of_mass (
                         input wire clk_in,
                         input wire rst_in,
                         input wire [10:0] x_in,
                         input wire [9:0]  y_in,
                         input wire valid_in,
                         input wire tabulate_in,
                         output logic [10:0] x_out,
                         output logic [9:0] y_out,
                         output logic valid_out);
	 // your code here

    logic [31:0] m_x;
    logic [31:0] m_y;
    logic [31:0] x_total; 
    logic [31:0] y_total;
    logic [31:0] x_r; 
    logic [31:0] y_r;
    logic [31:0] x_q; 
    logic [31:0] y_q;
    logic done_dividing_x;
    logic div_x_prev;
    logic error_x;
    logic busy_x;
    logic done_dividing_y;
    logic div_y_prev;
    logic error_y;
    logic busy_y;
    logic x_ready;
    logic y_ready;
    enum {IDLE, ADDING, DIVIDING, OUTPUT} state;

    divider #(
        .WIDTH(32)
    ) divide_x (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .dividend_in(x_total),
        .divisor_in(m_x),
        .data_valid_in(x_ready),
        .quotient_out(x_q),
        .remainder_out(x_r),
        .data_valid_out(done_dividing_x),
        .error_out(error_x),
        .busy_out(busy_x)
    );
    divider #(
        .WIDTH(32)
    ) divide_y (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .dividend_in(y_total),
        .divisor_in(m_y),
        .data_valid_in(y_ready),
        .quotient_out(y_q),
        .remainder_out(y_r),
        .data_valid_out(done_dividing_y),
        .error_out(error_y),
        .busy_out(busy_y)
    );

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            state <= IDLE;
            x_out <= 0;
            y_out <= 0;
            valid_out <= 0;
            m_x <= 0;
            m_y <= 0;
            x_total <= 0;
            y_total <= 0;
            x_ready <= 0;
            y_ready <= 0;
            div_x_prev <= 0;
            div_y_prev <= 0;
        end else begin
            case (state)
                IDLE: begin
                    // x_out <= 0;
                    // y_out <= 0;
                    valid_out <= 0;
                    m_x <= (valid_in)? 1:0;
                    m_y <= (valid_in)?1:0;
                    x_total <= (valid_in)? x_in:0;
                    y_total <= (valid_in)?y_in:0;
                    state <= (valid_in)? ADDING : IDLE;
                    div_x_prev <= 0;
                    div_y_prev <= 0;
                end
                ADDING: begin
                    x_total <= (valid_in)? x_total + x_in: x_total;
                    y_total <= (valid_in)? y_total + y_in: y_total;
                    m_y <= (valid_in)? m_y+1: m_y;
                    m_x <= (valid_in)? m_x+1: m_x;
                    valid_out <= 0;
                    state <= (m_x == 0 || m_y == 0)? IDLE: (tabulate_in)? DIVIDING: ADDING;
                    x_ready <= (tabulate_in && !busy_x && !busy_y)? 1:0;
                    y_ready <= (tabulate_in && !busy_x && !busy_y)? 1:0;
                end
                DIVIDING: begin
                    state <= ((done_dividing_x || div_x_prev) && (done_dividing_y || div_y_prev))? IDLE : DIVIDING;
                    div_x_prev <= (done_dividing_x)? 1: div_x_prev;
                    div_y_prev <= (done_dividing_y)? 1: div_y_prev;
                    x_out <= (done_dividing_x)? x_q: x_out;
                    y_out <= (done_dividing_y)? y_q: y_out;
                    valid_out <= ((done_dividing_x || div_x_prev) && (done_dividing_y || div_y_prev))? 1:0;
                    x_ready <= 0;
                    y_ready <= 0;
                end
                // OUTPUT: begin
                //     state <= (!error_x && !error_y)? IDLE : OUTPUT;
                //     x_out <= x_q;
                //     y_out <= y_q;
                //     valid_out <= 1;
                //     div_x_prev <= 0;
                //     div_y_prev <= 0;
                // end
            endcase
        end
    end

endmodule

`default_nettype wire
