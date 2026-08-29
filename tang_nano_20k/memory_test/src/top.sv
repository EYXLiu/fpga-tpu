module top (
    input  logic clk,
    input  logic uart_rx,
    output logic uart_tx,
    output logic led,
    output logic debug_led
);


    // UART RX

    logic [7:0] rx_data;
    logic       rx_valid;

    uart_rx #(
        .CLK_FREQ(27_000_000),
        .BAUD_RATE(115_200)
    ) uart (
        .clk(clk),
        .rx(uart_rx),
        .data(rx_data),
        .valid(rx_valid)
    );


    // UART PARSER

    logic        wr_en;
    logic [9:0]  wr_addr;
    logic [31:0] wr_data;

    logic        rd_en;
    logic [9:0]  rd_addr;

    logic        wr_done;

    uart_parser parser (
        .clk(clk),

        .rx_data(rx_data),
        .rx_valid(rx_valid),
        
        .wr_en(wr_en),
        .wr_addr(wr_addr),
        .wr_data(wr_data),

        .rd_en(rd_en),
        .rd_addr(rd_addr),

        .wr_done(wr_done)
    );

    // MEMORY

    logic [31:0] rd_data;

    logic        mem_rd_en;
    logic [9:0]  mem_rd_addr;

    memory #(
        .DATA_WIDTH(32),
        .ADDR_WIDTH(10)
    ) mem (
        .clk(clk),

        .wr_en(wr_en),
        .wr_addr(wr_addr),
        .wr_data(wr_data),

        .rd_en(mem_rd_en),
        .rd_addr(mem_rd_addr),
        .rd_data(rd_data)
    );

    // MEMORY CONTROLLER

    logic [7:0] tx_data;
    logic       tx_start;
    logic       tx_busy;

    memory_controller controller (
        .clk(clk),

        .rd_en(rd_en),
        .rd_addr(rd_addr),

        .rd_data(rd_data),

        .mem_rd_en(mem_rd_en),
        .mem_rd_addr(mem_rd_addr),

        .tx_data(tx_data),
        .tx_start(tx_start),
        .tx_busy(tx_busy),

        .wr_done(wr_done)
    );


    // UART TX

    uart_tx #(
        .CLK_FREQ(27_000_000),
        .BAUD_RATE(115_200)
    ) uart_sender (
        .clk(clk),
        .data(tx_data),
        .start(tx_start),
        .tx(uart_tx),
        .busy(tx_busy)
    );

    always_ff @(posedge clk) begin
        if (wr_done)
            led <= ~led;
    end

endmodule