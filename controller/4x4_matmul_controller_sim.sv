// multiply matrices
// A = [ 1  2  3  4]
//     [ 5  6  7  8]
//     [ 9 10 11 12]
//     [13 14 15 16]
// B = [17 18 19 20]
//     [21 22 23 24]
//     [25 26 27 28]
//     [29 30 31 32]
// expected answer:
//     [ 250  260  270  280]
//     [ 618  644  670  696]
//     [ 986 1028 1070 1112]
//     [1354 1412 1470 1528]

module sim;
    localparam N = 4;

    logic clk;
    logic rst;
    logic start;

    logic done;


    logic        a_rd_en;
    logic [9:0]  a_addr;
    logic [31:0] a_rd_data;

    logic        b_rd_en;
    logic [9:0]  b_addr;
    logic [31:0] b_rd_data;

    dual_unified_buffer #(
        .DATA_WIDTH(32),
        .ADDR_WIDTH(10)
    ) ub (

        .clk(clk),

        .a_wr_en(1'b0),
        .a_addr(a_addr),
        .a_wr_data(32'b0),
        .a_rd_en(a_rd_en),
        .a_rd_data(a_rd_data),

        .b_wr_en(1'b0),
        .b_addr(b_addr),
        .b_wr_data(32'b0),
        .b_rd_en(b_rd_en),
        .b_rd_data(b_rd_data)

    );

    logic [7:0] a_in [0:N-1];
    logic [7:0] b_in [0:N-1];

    logic [31:0] c [0:N-1][0:N-1];
    logic computing;

    nxn_matmul_controller #(
        .N(N)
    ) controller (

        .clk(clk),
        .rst(rst),

        .start(start),

        .a_rd_en(a_rd_en),
        .a_addr(a_addr),
        .a_rd_data(a_rd_data),

        .b_rd_en(b_rd_en),
        .b_addr(b_addr),
        .b_rd_data(b_rd_data),

        .a_in(a_in),
        .b_in(b_in),

        .c(c),

        .done(done),
        .computing(computing)
    );

    systolic_nxn #(
        .N(N)
    ) systolic (

        .clk(clk),
        .rst(rst),

        .a_in(a_in),
        .b_in(b_in),

        .c(c)

    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        #1;

        if (computing) begin
            $display(
                "cycle %0d | A = [%0d %0d %0d %0d] | B = [%0d %0d %0d %0d]",
                controller.compute_cycle,
                a_in[0], a_in[1], a_in[2], a_in[3],
                b_in[0], b_in[1], b_in[2], b_in[3]
            );
        end
    end

    initial begin

        clk = 0;
        rst = 1;
        start = 0;

        #20;
        rst = 0;

        // A =
        // [ 1  2  3  4]
        // [ 5  6  7  8]
        // [ 9 10 11 12]
        // [13 14 15 16]

        ub.mem[0] = {8'd1,  8'd2,  8'd3,  8'd4};
        ub.mem[1] = {8'd5,  8'd6,  8'd7,  8'd8};
        ub.mem[2] = {8'd9,  8'd10, 8'd11, 8'd12};
        ub.mem[3] = {8'd13, 8'd14, 8'd15, 8'd16};

        // B =
        // [17 18 19 20]
        // [21 22 23 24]
        // [25 26 27 28]
        // [29 30 31 32]

        ub.mem[4] = {8'd17, 8'd18, 8'd19, 8'd20};
        ub.mem[5] = {8'd21, 8'd22, 8'd23, 8'd24};
        ub.mem[6] = {8'd25, 8'd26, 8'd27, 8'd28};
        ub.mem[7] = {8'd29, 8'd30, 8'd31, 8'd32};

        #10;

        start = 1;

        #10;

        start = 0;

        wait(done);

        #20;

        $display("");
        $display("c");

        for (int i = 0; i < N; i++) begin

            $write("[ ");

            for (int j = 0; j < N; j++) begin
                $write("%0d ", c[i][j]);
            end

            $display("]");

        end


        #10;

        $finish;

    end
endmodule