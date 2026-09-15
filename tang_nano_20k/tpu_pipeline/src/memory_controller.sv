module memory_controller (
    input logic        clk,

    input logic        wr_en,
    input logic [9:0]  wr_addr,
    input logic [31:0] wr_data,

    input logic        rd_en,
    input logic [9:0]  rd_addr,
    input logic [31:0] rd_data,

    output logic        mem_wr_en,
    output logic [9:0]  mem_wr_addr,
    output logic [31:0] mem_wr_data,

    output logic        mem_rd_en,
    output logic [9:0]  mem_rd_addr,

    output logic [7:0] tx_data,
    output logic       tx_start,
    input  logic       tx_busy
);

    typedef enum logic [3:0] {
        IDLE,
        WAIT_DATA,
        CAPTURE_DATA,

        READ_START,
        READ_WAIT,

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

        mem_wr_en <= 1'b0;
        mem_rd_en <= 1'b0;
        tx_start  <= 1'b0;

        case (state)

            IDLE: begin

                if (wr_en) begin

                    mem_wr_en   <= 1'b1;
                    mem_wr_addr <= wr_addr;
                    mem_wr_data <= wr_data;

                    state <= WRITE_ACK_START;

                end

                else if (rd_en) begin

                    mem_rd_addr <= rd_addr;

                    state <= READ_START;

                end

            end

            READ_START: begin

                mem_rd_en <= 1'b1;

                state <= READ_WAIT;

            end

            READ_WAIT: begin

                state <= CAPTURE_DATA;
            
            end

            WRITE_ACK_START: begin

                if (!tx_busy) begin

                    tx_data  <= 8'h06;
                    tx_start <= 1'b1;

                    state <= WRITE_ACK_WAIT;

                end

            end


            WRITE_ACK_WAIT: begin

                if (!tx_busy)
                    state <= IDLE;

            end


            CAPTURE_DATA: begin

                data_reg <= rd_data;

                state <= SEND_3_START;

            end


            SEND_3_START: begin

                if (!tx_busy) begin

                    tx_data  <= data_reg[31:24];
                    tx_start <= 1'b1;

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
                    tx_start <= 1'b1;

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
                    tx_start <= 1'b1;

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
                    tx_start <= 1'b1;

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