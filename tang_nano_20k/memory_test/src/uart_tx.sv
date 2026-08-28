module uart_tx #(
    parameter CLK_FREQ  = 27_000_000,
    parameter BAUD_RATE = 115_200
) (
    input  logic       clk,

    input  logic [7:0] data,
    input  logic       start,

    output logic       tx,
    output logic       busy
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
        case (state)

            IDLE: begin
                tx <= 1;
                busy <= 0;
                clk_count <= 0;
                bit_index <= 0;

                if (start) begin
                    data_reg <= data;
                    busy <= 1;
                    state <= START;
                end
            end

            START: begin
                tx <= 0;

                if (clk_count == CLKS_PER_BIT - 1) begin
                    clk_count <= 0;
                    state <= DATA;
                end
                else begin
                    clk_count <= clk_count + 1;
                end
            end

            DATA: begin
                tx <= data_reg[bit_index];

                if (clk_count == CLKS_PER_BIT - 1) begin
                    clk_count <= 0;

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
                tx <= 1;

                if (clk_count == CLKS_PER_BIT - 1) begin
                    clk_count <= 0;
                    state <= IDLE;
                end
                else begin
                    clk_count <= clk_count + 1;
                end
            end

            default: begin
                tx <= 1;
                busy <= 0;
                clk_count <= 0;
                bit_index <= 0;
                state <= IDLE;
            end

        endcase
    end

endmodule