module memory #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 10
) (
    input logic clk,

    // write interface
    input logic                  wr_en,
    input logic [ADDR_WIDTH-1:0] wr_addr,
    input logic [DATA_WIDTH-1:0] wr_data,

    // read interface
    input logic                   rd_en,
    input logic [ADDR_WIDTH-1:0]  rd_addr,
    output logic [DATA_WIDTH-1:0] rd_data
);
    logic [DATA_WIDTH-1:0] mem [0:(1 << ADDR_WIDTH)-1];

    always_ff @(posedge clk) begin

        if (wr_en)
            mem[wr_addr] <= wr_data;

        if (rd_en)
            rd_data <= mem[rd_addr];
    
    end
endmodule