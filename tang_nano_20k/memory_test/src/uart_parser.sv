module uart_parser (
    input logic clk,

    input logic [7:0] rx_data,
    input logic       rx_valid,

    output logic        wr_en,
    output logic [9:0]  wr_addr,
    output logic [31:0] wr_data,

    output logic       rd_en,
    output logic [9:0] rd_addr,

    output logic wr_done
);

    typedef enum logic [3:0] {
        IDLE,

        WRITE_ADDR_HI,
        WRITE_ADDR_LO,
        WRITE_DATA_3,
        WRITE_DATA_2,
        WRITE_DATA_1,
        WRITE_DATA_0,
        WRITE_COMMIT,
        WRITE_WAIT,

        READ_ADDR_HI,
        READ_ADDR_LO
    } state_t;

    state_t state = IDLE;

    always_ff @(posedge clk) begin

        wr_en <= 0;
        rd_en <= 0;
        wr_done <= 0;

        case (state)

            IDLE: begin

                if (rx_valid) begin

                    if (rx_data == "W")
                        state <= WRITE_ADDR_HI;

                    else if (rx_data == "R")
                        state <= READ_ADDR_HI;

                end
            end


            WRITE_ADDR_HI: begin
                if (rx_valid) begin
                    wr_addr[9:8] <= rx_data;
                    state <= WRITE_ADDR_LO;
                end
            end


            WRITE_ADDR_LO: begin
                if (rx_valid) begin
                    wr_addr[7:0] <= rx_data;
                    state <= WRITE_DATA_3;
                end
            end


            WRITE_DATA_3: begin
                if (rx_valid) begin
                    wr_data[31:24] <= rx_data;
                    state <= WRITE_DATA_2;
                end
            end


            WRITE_DATA_2: begin
                if (rx_valid) begin
                    wr_data[23:16] <= rx_data;
                    state <= WRITE_DATA_1;
                end
            end


            WRITE_DATA_1: begin
                if (rx_valid) begin
                    wr_data[15:8] <= rx_data;
                    state <= WRITE_DATA_0;
                end
            end


            WRITE_DATA_0: begin
                if (rx_valid) begin
                    wr_data[7:0] <= rx_data;
                    state <= WRITE_COMMIT;
                end
            end


            WRITE_COMMIT: begin
                wr_en <= 1;
                wr_done <= 1;
                state <= IDLE;
            end


            READ_ADDR_HI: begin
                if (rx_valid) begin
                    rd_addr[9:8] <= rx_data;
                    state <= READ_ADDR_LO;
                end
            end


            READ_ADDR_LO: begin
                if (rx_valid) begin
                    rd_addr[7:0] <= rx_data;
                    state <= IDLE;

                    rd_en <= 1;
                end
            end

        endcase

    end

endmodule
