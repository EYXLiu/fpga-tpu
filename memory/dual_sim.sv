module sim;
    logic clk;

    logic        a_wr_en;
    logic [7:0]  a_addr;
    logic [31:0] a_wr_data;
    logic [31:0] a_rd_data;

    logic        b_wr_en;
    logic [7:0]  b_addr;
    logic [31:0] b_wr_data;
    logic [31:0] b_rd_data;

    dual_unified_buffer #(
        .DATA_WIDTH(32),
        .ADDR_WIDTH(8)
    ) dut (
        .clk(clk),

        .a_wr_en(a_wr_en),
        .a_addr(a_addr),
        .a_wr_data(a_wr_data),
        .a_rd_data(a_rd_data),

        .b_wr_en(b_wr_en),
        .b_addr(b_addr),
        .b_wr_data(b_wr_data),
        .b_rd_data(b_rd_data)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;

        a_wr_en = 0;
        a_addr = 0;
        a_wr_data = 0;

        b_wr_en = 0;
        b_addr = 0;
        b_wr_data = 0;

        // write through port a

        @(negedge clk);
        a_wr_en = 1;
        a_addr = 8'd0;
        a_wr_data = 32'd123;

        @(negedge clk);
        a_wr_en = 1;
        a_addr = 8'd1;
        a_wr_data = 32'd234;

        @(negedge clk);
        a_wr_en = 1;
        a_addr = 8'd2;
        a_wr_data = 32'd345;

        @(negedge clk);
        a_wr_en = 0;

        // read through port a

        a_addr = 8'd0;

        @(posedge clk);
        #1;

        $display("Address 0: %d", a_rd_data);

        a_addr = 8'd1;
        
        @(posedge clk);
        #1;

        $display("Address 1: %d", a_rd_data);

        a_addr = 8'd2;

        @(posedge clk);
        #1;

        $display("Address 2: %d", a_rd_data);

        // write through port b
        
        @(negedge clk);
        b_wr_en = 1;
        b_addr = 8'd0;
        b_wr_data = 32'd321;

        @(negedge clk);
        b_wr_en = 1;
        b_addr = 8'd1;
        b_wr_data = 32'd432;

        @(negedge clk);
        b_wr_en = 1;
        b_addr = 8'd2;
        b_wr_data = 32'd543;

        @(negedge clk);
        b_wr_en = 0;

        // read through port b

        b_addr = 8'd0;

        @(posedge clk);
        #1;

        $display("Address 0: %d", b_rd_data);

        b_addr = 8'd1;
        
        @(posedge clk);
        #1;

        $display("Address 1: %d", b_rd_data);

        b_addr = 8'd2;

        @(posedge clk);
        #1;

        $display("Address 2: %d", b_rd_data);

        // simultaneous write

        @(negedge clk);

        a_wr_en = 1;
        a_addr = 8'd20;
        a_wr_data = 32'd1234;

        b_wr_en = 1;
        b_addr = 8'd30;
        b_wr_data = 32'd4321;

        @(negedge clk);

        a_wr_en = 0;
        b_wr_en = 0;

        // simultaneous read

        a_addr = 8'd20;
        b_addr = 8'd30;

        @(posedge clk);
        #1;

        $display("Address 20 (a): %d", a_rd_data);
        $display("Address 30 (b): %d", b_rd_data);
        
        #10;
        $finish;
    end
endmodule

