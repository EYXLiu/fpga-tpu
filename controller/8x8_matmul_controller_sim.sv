// multiply matrices
// A = [ 1  2  3  4  5  6  7  8]
//     [ 9 10 11 12 13 14 15 16]
//     [17 18 19 20 21 22 23 24]
//     [25 26 27 28 29 30 31 32]
//     [33 34 35 36 37 38 39 40]
//     [41 42 43 44 45 46 47 48]
//     [49 50 51 52 53 54 55 56]
//     [57 58 59 60 61 62 63 64]
// B = [65  66  67  68  69  70  71  72]
//     [73  74  75  76  77  78  79  80]
//     [81  82  83  84  85  86  87  88]
//     [89  90  91  92  93  94  95  96]
//     [97  98  99 100 101 102 103 104]
//     [105 106 107 108 109 110 111 112]
//     [113 114 115 116 117 118 119 120]
//     [121 122 123 124 125 126 127 128]
// expected answer:
//     [  3684  3720  3756  3792  3828  3864  3900  3936]
//     [  9636  9736  9836  9936 10036 10136 10236 10336]
//     [ 15588 15752 15916 16080 16244 16408 16572 16736]
//     [ 21540 21768 21996 22224 22452 22680 22908 23136]
//     [ 27492 27784 28076 28368 28660 28952 29244 29536]
//     [ 33444 33800 34156 34512 34868 35224 35580 35936]
//     [ 39396 39816 40236 40656 41076 41496 41916 42336]
//     [ 45348 45832 46316 46800 47284 47768 48252 48736]

module sim;
    localparam N = 8;

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
                "cycle %0d | A = [%0d %0d %0d %0d %0d %0d %0d %0d] | B = [%0d %0d %0d %0d %0d %0d %0d %0d]",
                controller.compute_cycle,
                a_in[0], a_in[1], a_in[2], a_in[3],
                a_in[4], a_in[5], a_in[6], a_in[7],
                b_in[0], b_in[1], b_in[2], b_in[3],
                b_in[4], b_in[5], b_in[6], b_in[7]
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
        // [ 1  2  3  4  5  6  7  8]
        // [ 9 10 11 12 13 14 15 16]
        // [17 18 19 20 21 22 23 24]
        // [25 26 27 28 29 30 31 32]
        // [33 34 35 36 37 38 39 40]
        // [41 42 43 44 45 46 47 48]
        // [49 50 51 52 53 54 55 56]
        // [57 58 59 60 61 62 63 64]

        ub.mem[0]  = {8'd1,  8'd2,  8'd3,  8'd4};
        ub.mem[1]  = {8'd5,  8'd6,  8'd7,  8'd8};
        ub.mem[2]  = {8'd9,  8'd10, 8'd11, 8'd12};
        ub.mem[3]  = {8'd13, 8'd14, 8'd15, 8'd16};
        ub.mem[4]  = {8'd17, 8'd18, 8'd19, 8'd20};
        ub.mem[5]  = {8'd21, 8'd22, 8'd23, 8'd24};
        ub.mem[6]  = {8'd25, 8'd26, 8'd27, 8'd28};
        ub.mem[7]  = {8'd29, 8'd30, 8'd31, 8'd32};
        ub.mem[8]  = {8'd33, 8'd34, 8'd35, 8'd36};
        ub.mem[9]  = {8'd37, 8'd38, 8'd39, 8'd40};
        ub.mem[10] = {8'd41, 8'd42, 8'd43, 8'd44};
        ub.mem[11] = {8'd45, 8'd46, 8'd47, 8'd48};
        ub.mem[12] = {8'd49, 8'd50, 8'd51, 8'd52};
        ub.mem[13] = {8'd53, 8'd54, 8'd55, 8'd56};
        ub.mem[14] = {8'd57, 8'd58, 8'd59, 8'd60};
        ub.mem[15] = {8'd61, 8'd62, 8'd63, 8'd64};

        // B =
        // [65  66  67  68  69  70  71  72]
        // [73  74  75  76  77  78  79  80]
        // [81  82  83  84  85  86  87  88]
        // [89  90  91  92  93  94  95  96]
        // [97  98  99 100 101 102 103 104]
        // [105 106 107 108 109 110 111 112]
        // [113 114 115 116 117 118 119 120]
        // [121 122 123 124 125 126 127 128]

        ub.mem[16] = {8'd65,  8'd66,  8'd67,  8'd68};
        ub.mem[17] = {8'd69,  8'd70,  8'd71,  8'd72};
        ub.mem[18] = {8'd73,  8'd74,  8'd75,  8'd76};
        ub.mem[19] = {8'd77,  8'd78, 8'd79, 8'd80};
        ub.mem[20] = {8'd81, 8'd82, 8'd83, 8'd84};
        ub.mem[21] = {8'd85, 8'd86, 8'd87, 8'd88};
        ub.mem[22] = {8'd89, 8'd90, 8'd91, 8'd92};
        ub.mem[23] = {8'd93, 8'd94, 8'd95, 8'd96};
        ub.mem[24] = {8'd97, 8'd98, 8'd99, 8'd100};
        ub.mem[25] = {8'd101, 8'd102, 8'd103, 8'd104};
        ub.mem[26] = {8'd105, 8'd106, 8'd107, 8'd108};
        ub.mem[27] = {8'd109, 8'd110, 8'd111, 8'd112};
        ub.mem[28] = {8'd113, 8'd114, 8'd115, 8'd116};
        ub.mem[29] = {8'd117, 8'd118, 8'd119, 8'd120};
        ub.mem[30] = {8'd121, 8'd122, 8'd123, 8'd124};
        ub.mem[31] = {8'd125, 8'd126, 8'd127, 8'd128};

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