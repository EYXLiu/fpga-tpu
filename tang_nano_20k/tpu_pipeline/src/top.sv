module top (
    input  logic clk,
    input  logic rst,
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
    ) uart_rx_inst (
        .clk(clk),
        .rx(uart_rx),
        .data(rx_data),
        .valid(rx_valid)
    );

    // UART TX

    logic [7:0] tx_data;
    logic       tx_start;
    logic       tx_busy;

    uart_tx #(
        .CLK_FREQ(27_000_000),
        .BAUD_RATE(115_200)
    ) uart_tx_inst (
        .clk(clk),
        .tx(uart_tx),
        .data(tx_data),
        .start(tx_start),
        .busy(tx_busy)
    );

    // UART PARSER

    logic        wr_en;
    logic [9:0]  wr_addr;
    logic [31:0] wr_data;

    logic        rd_en;
    logic [9:0]  rd_addr;

    logic        wr_done;
    logic        start_matmul;

    uart_parser parser (
        .clk(clk),

        .rx_data(rx_data),
        .rx_valid(rx_valid),

        .wr_en(wr_en),
        .wr_addr(wr_addr),
        .wr_data(wr_data),

        .rd_en(rd_en),
        .rd_addr(rd_addr),

        .wr_done(wr_done),
        .start_matmul(start_matmul)
    );

    // UART MEMORY CONTROLLER

    logic [31:0] host_rd_data;

    logic        host_mem_wr_en;
    logic [9:0]  host_mem_wr_addr;
    logic [31:0] host_mem_wr_data;

    logic        host_mem_rd_en;
    logic [9:0]  host_mem_rd_addr;

    memory_controller mem_controller (
        .clk(clk),

        .wr_en(wr_en),
        .wr_addr(wr_addr),
        .wr_data(wr_data),

        .rd_en(rd_en),
        .rd_addr(rd_addr),
        .rd_data(host_rd_data),

        .mem_wr_en(host_mem_wr_en),
        .mem_wr_addr(host_mem_wr_addr),
        .mem_wr_data(host_mem_wr_data),

        .mem_rd_en(host_mem_rd_en),
        .mem_rd_addr(host_mem_rd_addr),

        .tx_data(tx_data),
        .tx_start(tx_start),
        .tx_busy(tx_busy)
    );

    // MATMUL CONTROLLER

    logic        matmul_done;
    logic        matmul_computing;

    logic        mat_mem_rd_en;
    logic [9:0]  mat_mem_addr;
    logic [31:0] mat_mem_rd_data;

    logic [7:0] mat_a_in [0:3];
    logic [7:0] mat_b_in [0:3];

    logic [31:0] c [0:3][0:3];


    nxn_matmul_controller #(
        .N(4),
        .M(4),
        .K(4)
    ) matmul (
        .clk(clk),
        .rst(rst),

        .start(start_matmul),

        .mem_rd_en(mat_mem_rd_en),
        .mem_addr(mat_mem_addr),
        .mem_rd_data(mat_mem_rd_data),

        .a_in(mat_a_in),
        .b_in(mat_b_in),

        .c(c),

        .done(matmul_done),
        .computing(matmul_computing)
    );

    // SYSTOLIC ARRAY

    systolic_array #(
        .N(4),
        .M(4)
    ) systolic (
        .clk(clk),
        .rst(rst),

        .a_in(mat_a_in),
        .b_in(mat_b_in),

        .c(c)
    );

    // SINGLE-PORT MEMORY

    logic        mem_wr_en;
    logic [9:0]  mem_wr_addr;
    logic [31:0] mem_wr_data;

    logic        mem_rd_en;
    logic [9:0]  mem_rd_addr;
    logic [31:0] mem_rd_data;


    memory #(
        .DATA_WIDTH(32),
        .ADDR_WIDTH(10)
    ) buffer (
        .clk(clk),

        .wr_en(mem_wr_en),
        .wr_addr(mem_wr_addr),
        .wr_data(mem_wr_data),

        .rd_en(mem_rd_en),
        .rd_addr(mem_rd_addr),
        .rd_data(mem_rd_data)
    );

    typedef enum logic [1:0] {
        TOP_IDLE,
        TOP_COMPUTE,
        TOP_WAIT,
        TOP_STORE_C
    } state_t;

    state_t state;

    logic [4:0] c_store_idx;


    always_ff @(posedge clk) begin

        if (rst) begin

            state       <= TOP_IDLE;
            c_store_idx <= 5'd0;

            led       <= 1'b0;
            debug_led <= 1'b0;

        end

        else begin

            case (state)

                TOP_IDLE: begin

                    if (start_matmul)
                        state <= TOP_COMPUTE;

                    if (wr_done)
                        led <= ~led;

                end


                TOP_COMPUTE: begin

                    if (matmul_done) begin

                        state <= TOP_WAIT;

                        debug_led <= ~debug_led;

                    end

                end

                TOP_WAIT: begin

                    c_store_idx <= 5'd0;

                    state <= TOP_STORE_C;
                
                end


                TOP_STORE_C: begin

                    if (c_store_idx == 5'd15) begin

                        state <= TOP_IDLE;

                    end

                    else begin

                        c_store_idx <= c_store_idx + 1'b1;

                    end

                end


                default: begin

                    state <= TOP_IDLE;

                end

            endcase

        end

    end

    // MEMORY ROUTING

    always_comb begin

        // Defaults

        mem_wr_en   = 1'b0;
        mem_rd_addr = 10'd0;
        mem_wr_addr = 10'd0;
        mem_wr_data = 32'd0;

        mem_rd_en   = 1'b0;


        // Memory output is shared by host and matmul.

        host_rd_data   = mem_rd_data;
        mat_mem_rd_data = mem_rd_data;

        // COMPUTE

        if (state == TOP_COMPUTE) begin

            mem_rd_en = mat_mem_rd_en;
            mem_rd_addr  = mat_mem_addr;

        end

        // STORE C

        else if (state == TOP_STORE_C) begin

            mem_wr_en = 1'b1;

            // C occupies addresses 8-23

            mem_wr_addr = 10'd8 + c_store_idx;

            mem_wr_data =
                c[c_store_idx / 4][c_store_idx % 4];

        end

        // IDLE / UART

        else begin

            mem_wr_en   = host_mem_wr_en;
            mem_wr_addr    = host_mem_wr_addr;
            mem_wr_data = host_mem_wr_data;

            mem_rd_en = host_mem_rd_en;

            mem_rd_addr = host_mem_rd_addr;

        end

    end

endmodule