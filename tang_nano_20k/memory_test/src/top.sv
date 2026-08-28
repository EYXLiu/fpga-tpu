module top (
    input  logic clk,
    input  logic uart_rx,
    output logic uart_tx,
    output logic led
);

    logic [7:0] rx_data;
    logic       rx_valid;
    
    logic       tx_start;
    logic       tx_busy;

    uart_rx #(
        .CLK_FREQ(27_000_000),
        .BAUD_RATE(115_200)
    ) uart (
        .clk(clk),
        .rx(uart_rx),
        .data(rx_data),
        .valid(rx_valid)
    );

    uart_tx #(
        .CLK_FREQ(27_000_000),
        .BAUD_RATE(115_200)
    ) uart_sender (
        .clk(clk),
        .data(rx_data),
        .start(tx_start),
        .tx(uart_tx),
        .busy(tx_busy)
    );

    always_ff @(posedge clk) begin
        tx_start <= 0;

        if (rx_valid && !tx_busy) begin
            tx_start <= 1;
        end
    end

endmodule