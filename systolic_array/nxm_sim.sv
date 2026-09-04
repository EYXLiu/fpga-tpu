// multiply matrices
// A = [ 1  2  3  4]
//     [ 5  6  7  8]
// B = [ 9 10 11]
//     [12 13 14]
//     [15 16 17]
//     [18 19 20]
// expected answer:
//     [150 160 170]
//     [366 392 418]

module sim;

    logic clk;
    logic rst;

    logic [7:0] a[0:1];
    logic [7:0] b[0:2];

    logic [31:0] c [0:1][0:2];

    systolic_nxm #(
        .N(2),
        .M(3)
    ) dut (
        .clk(clk),
        .rst(rst),

        .a_in(a),
        .b_in(b),

        .c(c)
    );

    // Clock
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;

        a[0] = 0;
        a[1] = 0;

        b[0] = 0;
        b[1] = 0;
        b[2] = 0;

        // Reset
        #10;
        rst = 0;

        // Cycle 1
        a[0] = 1;
        a[1] = 0;

        b[0] = 9;
        b[1] = 0;
        b[2] = 0;

        #10;

        // Cycle 2
        a[0] = 2;
        a[1] = 5;

        b[0] = 12;
        b[1] = 10;
        b[2] = 0;

        #10;

        // Cycle 3
        a[0] = 3;
        a[1] = 6;

        b[0] = 15;
        b[1] = 13;
        b[2] = 11;

        #10;

        // Cycle 4
        a[0] = 4;
        a[1] = 7;

        b[0] = 18;
        b[1] = 16;
        b[2] = 14;

        #10;

        // Cycle 5
        a[0] = 0;
        a[1] = 8;

        b[0] = 0;
        b[1] = 19;
        b[2] = 17;

        #10;

        // Cycle 6
        a[0] = 0;
        a[1] = 0;

        b[0] = 0;
        b[1] = 0;
        b[2] = 20;

        #10;

        // Cycle 7
        a[0] = 0;
        a[1] = 0;

        b[0] = 0;
        b[1] = 0;
        b[2] = 0;

        #30;

        $display("C =");
        $display("[%0d %0d %0d]",
            c[0][0], c[0][1], c[0][2]);
        $display("[%0d %0d %0d]",
            c[1][0], c[1][1], c[1][2]);

        $finish;
    end

endmodule