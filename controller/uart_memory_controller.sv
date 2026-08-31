module uart_memory_controller (
    input logic        clk,

    input logic        rd_en,
    input logic [9:0]  rd_addr,

    input logic [31:0] rd_data,

    output logic       mem_rd_en,
    output logic [9:0] mem_rd_addr,

    output logic [7:0] tx_data,
    output logic       tx_start,
    input logic        tx_busy,

    input logic        wr_done
);

    typedef enum logic [3:0] {
        IDLE,
        WAIT_DATA,
        CAPTURE_DATA,

        WRITE_ACK_START,
        WRITE_ACK_WAIT,

        SEND_3_START,
        SEND_3_WAIT,

        SEND_2_START,
        SEND_2_WAIT,

        SEND_1_START,
        SEND_1_WAIT,

        SEND_0_START,
        SEND_0_WAIT
    } state_t;

    state_t state = IDLE;

    logic [31:0] data_reg;


    always_ff @(posedge clk) begin

        mem_rd_en <= 0;
        tx_start  <= 0;

        case (state)

            IDLE: begin

                if (wr_done) begin

                    state <= WRITE_ACK_START;

                end

                else if (rd_en) begin

                    mem_rd_addr <= rd_addr;
                    mem_rd_en <= 1;
                    state <= WAIT_DATA;

                end

            end

            WRITE_ACK_START: begin

                if (!tx_busy) begin
                    tx_data <= 8'h06;
                    tx_start <= 1;

                    state <= WRITE_ACK_WAIT;
                end
            
            end

            WRITE_ACK_WAIT: begin

                if (!tx_busy)
                    state <= IDLE;
                
            end

            WAIT_DATA: begin

                state <= CAPTURE_DATA;

            end

            CAPTURE_DATA: begin

                data_reg <= rd_data;

                state <= SEND_3_START;

            end

            SEND_3_START: begin

                if (!tx_busy) begin

                    tx_data  <= data_reg[31:24];
                    tx_start <= 1;

                    state <= SEND_3_WAIT;

                end

            end

            SEND_3_WAIT: begin

                if (!tx_busy)
                    state <= SEND_2_START;

            end

            SEND_2_START: begin

                if (!tx_busy) begin

                    tx_data  <= data_reg[23:16];
                    tx_start <= 1;

                    state <= SEND_2_WAIT;

                end

            end

            SEND_2_WAIT: begin

                if (!tx_busy)
                    state <= SEND_1_START;

            end

            SEND_1_START: begin

                if (!tx_busy) begin

                    tx_data  <= data_reg[15:8];
                    tx_start <= 1;

                    state <= SEND_1_WAIT;

                end

            end

            SEND_1_WAIT: begin

                if (!tx_busy)
                    state <= SEND_0_START;

            end

            SEND_0_START: begin

                if (!tx_busy) begin

                    tx_data  <= data_reg[7:0];
                    tx_start <= 1;

                    state <= SEND_0_WAIT;

                end

            end

            SEND_0_WAIT: begin

                if (!tx_busy)
                    state <= IDLE;

            end

            default: begin
                state <= IDLE;
            end

        endcase

    end

endmodule