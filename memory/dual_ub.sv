module dual_unified_buffer #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 10
) (
    input logic clk,

    // port a
    input logic                   a_wr_en,
    input logic [ADDR_WIDTH-1:0]  a_addr,
    input logic [DATA_WIDTH-1:0]  a_wr_data,
    input logic                   a_rd_en,
    output logic [DATA_WIDTH-1:0] a_rd_data,

    // port b
    input logic                   b_wr_en,
    input logic [ADDR_WIDTH-1:0]  b_addr,
    input logic [DATA_WIDTH-1:0]  b_wr_data,
    input logic                   b_rd_en,
    output logic [DATA_WIDTH-1:0] b_rd_data
);

    logic [DATA_WIDTH-1:0] mem [0:(1 << ADDR_WIDTH)-1];

    always_ff @(posedge clk) begin

        if (a_wr_en)
            mem[a_addr] <= a_wr_data;

        if (b_wr_en)
            mem[b_addr] <= b_wr_data;

        if (a_rd_en)
            a_rd_data <= mem[a_addr];

        if (b_rd_en)
            b_rd_data <= mem[b_addr];
    
    end
endmodule
