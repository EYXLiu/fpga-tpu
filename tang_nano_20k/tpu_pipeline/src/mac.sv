module mac (
    input logic clk,
    input logic rst,

    input logic [7:0] a,
    input logic [7:0] b,

    output logic [31:0] acc
);


    always_ff @(posedge clk) begin
        if (rst)
            acc <= 32'd0;
        else
            acc <= acc + a * b;
    end

endmodule
