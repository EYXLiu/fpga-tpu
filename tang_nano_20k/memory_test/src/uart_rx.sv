module uart_rx #(
    parameter CLK_FREQ  = 27_000_000,
    parameter BAUD_RATE = 115_200
) (
    input  logic       clk,
    input  logic       rx,
    output logic [7:0] data,
    output logic       valid
);

    localparam integer CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;

    logic [15:0] clk_count = 0;
    logic [3:0]  bit_index = 0;
    logic [7:0]  data_reg = 0;

    typedef enum logic [1:0] {
        IDLE,
        START,
        DATA,
        STOP
    } state_t;

    state_t state = IDLE;

    always_ff @(posedge clk) begin
        valid <= 0;

        case (state)

            IDLE: begin
                clk_count <= 0;
                bit_index <= 0;

                if (!rx)
                    state <= START;
            end

            START: begin
                if (clk_count == (CLKS_PER_BIT / 2)) begin
                    clk_count <= 0;

                    if (!rx)
                        state <= DATA;
                    else
                        state <= IDLE;
                end
                else begin
                    clk_count <= clk_count + 1;
                end
            end

            DATA: begin
                if (clk_count == CLKS_PER_BIT - 1) begin
                    clk_count <= 0;

                    data_reg[bit_index] <= rx;

                    if (bit_index == 7) begin
                        bit_index <= 0;
                        state <= STOP;
                    end
                    else begin
                        bit_index <= bit_index + 1;
                    end
                end
                else begin
                    clk_count <= clk_count + 1;
                end
            end

            STOP: begin
                if (clk_count == CLKS_PER_BIT - 1) begin
                    clk_count <= 0;

                    data <= data_reg;
                    valid <= 1;

                    state <= IDLE;
                end
                else begin
                    clk_count <= clk_count + 1;
                end
            end

            default: begin
                state <= IDLE;
                clk_count <= 0;
            end

        endcase
    end

endmodule