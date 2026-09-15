module nxn_matmul_controller #(
    parameter N = 4,
    parameter M = 4,
    parameter K = 4
) (
    input logic clk,
    input logic rst,

    input logic start,

    output logic        mem_rd_en,
    output logic [9:0]  mem_addr,
    input logic [31:0]  mem_rd_data,

    output logic [7:0] a_in [0:N-1],
    output logic [7:0] b_in [0:K-1],
    input logic [31:0] c [0:N-1][0:K-1],

    output logic done,
    output logic computing
);

    localparam ELEMENTS_PER_WORD = 4;

    localparam A_WORDS_PER_ROW =
        (M + ELEMENTS_PER_WORD - 1) / ELEMENTS_PER_WORD;

    localparam B_WORDS_PER_ROW =
        (K + ELEMENTS_PER_WORD - 1) / ELEMENTS_PER_WORD;

    localparam B_BASE = N * A_WORDS_PER_ROW;

    typedef enum logic [3:0] {
        IDLE,

        READ_A_REQ,
        READ_A_WAIT,
        READ_A_CAPTURE,

        READ_B_REQ,
        READ_B_WAIT,
        READ_B_CAPTURE,
        
        COMPUTE,
        FLUSH,
        FINISH
    } state_t;

    state_t state;

    logic [7:0] A [0:N-1][0:M-1];
    logic [7:0] B [0:M-1][0:K-1];


    integer a_row;
    integer b_row;

    integer a_word_idx;
    integer b_word_idx;

    integer compute_cycle;

    always_ff @(posedge clk) begin

        if (rst) begin

            state <= IDLE;

            a_row <= 0;
            b_row <= 0;

            a_word_idx <= 0;
            b_word_idx <= 0;

            compute_cycle <= 0;

            mem_rd_en <= 1'b0;
            mem_addr  <= 10'd0;

            done      <= 1'b0;
            computing <= 1'b0;

            for (int i = 0; i < N; i++) begin
                a_in[i] <= 8'd0;
            end

            for (int j = 0; j < K; j++) begin
                b_in[j] <= 8'd0;
            end

        end

        else begin

            // Pulse signals
            mem_rd_en <= 1'b0;
            done      <= 1'b0;


            case (state)

                IDLE: begin

                    computing <= 1'b0;

                    if (start) begin

                        a_row      <= 0;
                        b_row      <= 0;

                        a_word_idx <= 0;
                        b_word_idx <= 0;

                        state <= READ_A_REQ;

                    end

                end


                READ_A_REQ: begin

                    mem_rd_en <= 1'b1;

                    mem_addr <=
                        10'(a_row * A_WORDS_PER_ROW
                        + a_word_idx);

                    state <= READ_A_WAIT;

                end

                READ_A_WAIT: begin

                    state <= READ_A_CAPTURE;

                end

                READ_A_CAPTURE: begin

                    for (int k = 0; k < ELEMENTS_PER_WORD; k++) begin

                        int elem_idx;

                        elem_idx =
                            a_word_idx * ELEMENTS_PER_WORD + k;

                        if (elem_idx < M) begin

                            A[a_row][elem_idx] <=
                                mem_rd_data[31 - k*8 -: 8];

                        end

                    end


                    if (a_word_idx == A_WORDS_PER_ROW - 1) begin

                        a_word_idx <= 0;

                        if (a_row == N - 1) begin

                            b_row      <= 0;
                            b_word_idx <= 0;

                            state <= READ_B_REQ;

                        end

                        else begin

                            a_row <= a_row + 1;

                            state <= READ_A_REQ;

                        end

                    end

                    else begin

                        a_word_idx <= a_word_idx + 1;

                        state <= READ_A_REQ;

                    end

                end

                READ_B_REQ: begin

                    mem_rd_en <= 1'b1;

                    mem_addr <=
                        10'(B_BASE
                        + b_row * B_WORDS_PER_ROW
                        + b_word_idx);

                    state <= READ_B_WAIT;

                end

                READ_B_WAIT: begin

                    state <= READ_B_CAPTURE;

                end

                READ_B_CAPTURE: begin

                    for (int k = 0; k < ELEMENTS_PER_WORD; k++) begin

                        int elem_idx;

                        elem_idx =
                            b_word_idx * ELEMENTS_PER_WORD + k;

                        if (elem_idx < K) begin

                            B[b_row][elem_idx] <=
                                mem_rd_data[31 - k*8 -: 8];

                        end

                    end


                    if (b_word_idx == B_WORDS_PER_ROW - 1) begin

                        b_word_idx <= 0;

                        if (b_row == M - 1) begin

                            compute_cycle <= 0;

                            state <= COMPUTE;

                        end

                        else begin

                            b_row <= b_row + 1;

                            state <= READ_B_REQ;

                        end

                    end

                    else begin

                        b_word_idx <= b_word_idx + 1;

                        state <= READ_B_REQ;

                    end

                end

                COMPUTE: begin

                    computing <= 1'b1;


                    // Feed A

                    for (int i = 0; i < N; i++) begin

                        if (
                            compute_cycle >= i &&
                            compute_cycle < i + M
                        ) begin

                            a_in[i] <=
                                A[i][compute_cycle - i];

                        end

                        else begin

                            a_in[i] <= 8'd0;

                        end

                    end


                    // Feed B

                    for (int j = 0; j < K; j++) begin

                        if (
                            compute_cycle >= j &&
                            compute_cycle < j + M
                        ) begin

                            b_in[j] <=
                                B[compute_cycle - j][j];

                        end

                        else begin

                            b_in[j] <= 8'd0;

                        end

                    end


                    if (compute_cycle == N + M + K) begin

                        computing <= 1'b0;

                        state <= FLUSH;

                    end

                    else begin

                        compute_cycle <= compute_cycle + 1;

                    end

                end

                FLUSH: begin

                    state <= FINISH;

                end

                FINISH: begin

                    done <= 1'b1;

                    state <= IDLE;

                end


                default: begin

                    state <= IDLE;

                end

            endcase

        end

    end

endmodule