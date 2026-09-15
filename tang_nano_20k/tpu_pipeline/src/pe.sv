module pe (
    input logic clk,
    input logic rst,

    input logic [7:0] a_in,
    input logic [7:0] b_in,

    output logic [7:0] a_out,
    output logic [7:0] b_out,

    output logic [31:0] acc
);

    mac mac (
        .clk(clk),
        .rst(rst),
        .a(a_in),
        .b(b_in),
        .acc(acc)
    );

    always_ff @(posedge clk) begin
        if (rst) begin
            a_out <= 8'd0;
            b_out <= 8'd0;
        end
        else begin
            a_out <= a_in;
            b_out <= b_in;
        end
    end

endmodule
